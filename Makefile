PGSQL_CONTAINER_ID=`cat postgres.container.id`

createdb:
	docker run \
		--name postgres-tegra118 \
		-e POSTGRES_PASSWORD=password \
		-p 5500:5432 \
		-d postgres \
		> postgres.container.id
	sleep 5
	PGPASSWORD=password psql -p 5500 -U postgres -h localhost \
		-c 'CREATE DATABASE tegra118;'

startdb:
	docker start $(PGSQL_CONTAINER_ID)

stopdb:
	docker stop $(PGSQL_CONTAINER_ID)

deletedb:
	-docker stop $(PGSQL_CONTAINER_ID)
	docker rm $(PGSQL_CONTAINER_ID)
	rm postgres.container.id

connect:
	PGPASSWORD=password psql -p 5500 -U postgres -h localhost tegra118
