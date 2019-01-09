--todo... create a proc, make this modular
--lists all indexes for ALL databases on server without a cursor

declare @sql varchar(max) = ''

select @sql = @sql 
		+ 'use ' 
		+ quotename(name) 
		+ char(13) 
		+ 'select DBNAME = ''' 
		+ name 
		+ ''',	
				TableName = t.name,
				IndexName = ind.name,
				IndexType = ind.type_desc,
				IsUnique =  ind.is_unique,
				IndexId = ind.index_id,
				ColumnId = ic.index_column_id,
				ColumnName = col.name,
				SchemaName = s.name
			FROM 
				sys.indexes ind 
			INNER JOIN 
				sys.index_columns ic ON  ind.object_id = ic.object_id and ind.index_id = ic.index_id 
			INNER JOIN 
				sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id 
			INNER JOIN 
				sys.tables t ON ind.object_id = t.object_id
			INNER JOIN
				sys.schemas s ON t.schema_id = s.schema_id; '  
		+ char(13) 
		from sys.databases
		where state = 0 and name not in ('master','tempdb','model','msdb')
exec(@sql)
