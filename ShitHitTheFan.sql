use AdminTools
go

/*
  TODO: A lot... 
  Dependent on 
    sp_WhoIsActive    http://whoisactive.com/
    sp_BlitzWho       https://www.brentozar.com/first-aid/sp_blitzwho/
  
*/

declare @spid int = 176
declare @show_sleeping_spids_val tinyint = 1 
												--2 = show all connected sessions
												--1 = DEFAULT pulls sleeping SPIDs that ALSO have an open tran
												--0 = does not pull any sleeping SPIDs
declare @filterForSpid bit = 0
declare @showLogspace bit = 1
declare @inputBuffer bit = 1
declare @opentranDB sysname = 'tempdb'
declare @whoIsActive bit = 1
declare @blitzWho bit = 0


--don't change these, unless you really want to :)
declare @filter_type_val varchar(10) = 'session'
declare @filter_val sysname = ''

if @filterForSpid = 1 and @filter_type_val = 'session'
begin
	set @filter_val = @spid
end

if @opentranDB is not null and @opentranDB <> ''
begin
	declare @sql varchar(max)
	set @sql = 'dbcc opentran(' + quotename(@opentranDB) + ') WITH TABLERESULTS' 
	exec (@sql)
end

if @showLogspace = 1
begin
	dbcc sqlperf ('logspace')
end

if @inputBuffer = 1 and @spid is not null
begin
	select 'INPUTBUFFER Info for ' + cast(@spid as varchar)
	dbcc inputbuffer(@spid)
end

if @whoIsActive = 1
begin
	exec sp_WhoIsActive 
			@show_sleeping_spids = @show_sleeping_spids_val
			--2 = show all connected sessions
			--1 = DEFAULT pulls sleeping SPIDs that ALSO have an open tran
			--0 = does not pull any sleeping SPIDs
		
			,@get_full_inner_text = 1
			--1 = gets the full stored proc or running batch
			--0 = DEFAULT gets only the actual statement that is currently running in the batch
		
			,@get_outer_command = 1
			--1 = gets the associated outer adhoc query or stored procedure call
			--0 = DEFAULT
		
			,@get_additional_info = 0
			--1 = gets non-performance related info, and if Agent Job is running get some info on that (job_id, name, step)
			--0 = DEFAULT
		
			,@find_block_leaders = 1
			--1 = walk the blocking chain and count eht enumber of SPIDS blocked
			--0 = DEFAULT

			,@get_avg_time = 1
			--1 = [dd hh:mm:ss.mss (avg)]	This column reflects the average run time—if it’s available—of the statement that your request is currently working on
			--								Allows you compare the avg run time against the current runtime to see if it's abnormal

			,@get_transaction_info = 1
			--1 = Enables pulling transaction log write info and duration
			--0 = default

				/*
				[tran_log_writes]	column includes information about any database that has been written to on behalf of the transaction
				[tran_start_time]	column reflects the time that the first database was written to on behalf of the transaction. 
									This is perhaps a bit counter-intuitive, but the idea is simple: for the most part it’s not interesting 
									to see a lot of information about read-only transactions. Millions of them start and finish every day on 
									the average SQL Server instance. Transactions that are actually doing some work—writing something—are the ones 
									that tend to cause the issues
				*/
		
			,@filter_type =	@filter_type_val		--'login'
			,@filter = @filter_val					--'samc2000\thatguy'
			/*
			These filters are additive. This means that if you’re looking for information on session_id 96, 
			but that session is sleeping, and you have @show_sleeping_spids set to 0, you’re not going to see any information
			Also, they support wildcard % for the @filter

			@filter_type	supports 5 filters (for 5 columns)
							"session"	filters on the [session_id] column
							"program"	filters on the [program_name] column
							"database"	filters on the [database_name] column
							"login"		filters on the [login_name] column
							"host"		filters on the [host_name] column
			*/

			--@not_filter_type = 'login'
			--@not_filter = 'samc2000\thatguy'
			--opposite of the above. i.e. show everything except for thatguy instead of only for thatguy
		
			--@get_task_info = 2

			--,@output_column_list = '[dd%],[session_id]'
			--self explanatory, but you need to return the column of enabled features or it's useless

			--@sort_order = '[start_time] ASC' --list the columns you want results sorted by
			--self explanatory

			--@destination_table = 'dbo.SomeTable'
			--if you want to log the results. You need to have the table first, it doesn't check for it
			--http://whoisactive.com/docs/25_capturing/
		
			--,@help = 1
			--read the rest of the parameters

			/*
			TEMPDB Notes:		Each of the columns reports a number of 8 KB pages. The [tempdb_allocations] column is collected directly 
								from the tempdb-related DMVs, and indicates how many pages were allocated in tempdb due to temporary tables, 
								LOB types, spools, or other consumers. The [tempdb_current] column is computed by subtracting the deallocated 
								pages information reported by the tempdb DMVs from the number of allocations. Seeing a high number of allocations 
								with a small amount of current pages means that your query may be slamming tempdb, but is not causing it to grow. 
								Seeing a large number of current pages means that your query may be responsible for all of those auto-grows you keep noticing.

			
			[open_tran_count]	by far the most useful column that Who is Active pulls from the deprecated sysprocesses view. And only from that view, 
								since Microsoft has not bothered replicating it elsewhere. It can be used not only to tell whether the session has an 
								active transaction, but also to find out how deeply nested the transaction is. This is invaluable information when debugging 
								situations where applications open several nested transactions and don’t send enough commits to seal the deal.

			sleeping / active	the data from sleeping sessions and active requests is both reported by Who is Active, but never at the same time for the same session
								if the [status] column is “sleeping,” it means that all of the values reported by Who is Active for that session are session-level metrics. 
								If the status is anything other than “sleeping” (most commonly “running,” “runnable,” or “suspended”), then the values reported are all request-level metrics
								[dd hh:mm:ss.mss]	For a sleeping session refers to the amount of time elapsed since login time. 
													For a request it’s the amount of time the entire batch—not just the current statement—has been running.
								[sql_text]			For a sleeping session is the last batch run on behalf of the session. 
													For a request it’s the currently-running statement (at least, by default).
								[wait_info]			Is always NULL for a sleeping session.
								[CPU] and [reads]	Are session-level metrics (aggregates across all requests processed since login) for sleeping sessions, 
													and request-level metrics (relevant only as far as the current request) for active requests.
								If you see a lot of sleeping sessions showing up in the default Who is Active view, you might want to ask some questions of your application developer colleagues. 
								Why is the application beginning transactions and letting them sit around for long periods of time? This is generally not a great I idea
		
			Processing			Refresher on how queries are processed http://whoisactive.com/docs/13_queries/					
			*/
end

if @blitzWho = 1
begin
	exec sp_BlitzWho
			@Help = 0
			,@ShowSleepingSPIDs = 1
			,@ExpertMode = 0
end
