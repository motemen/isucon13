APP = isupipe

all: $(APP)

always:

### app

$(APP): webapp/go/*.go always
	cd webapp/go && go get && GOOS=linux GOARCH=amd64 go build -ldflags "-s -w" -o ../../$(APP)

deploy: $(APP) stop scp scp-sql start
# deploy: stop reset-logs scp scp-sql scp-docker-compose start

scp: $(APP)
	scp ./$(APP) isu11:/home/isucon/webapp/go/$(APP) & \
	scp ./$(APP) isu12:/home/isucon/webapp/go/$(APP) & \
	scp ./$(APP) isu13:/home/isucon/webapp/go/$(APP) & \
	wait

scp-sql:
	scp -r ./webapp/sql isu11:/home/isucon/webapp & \
	scp -r ./webapp/sql isu12:/home/isucon/webapp & \
	scp -r ./webapp/sql isu13:/home/isucon/webapp & \
	wait

scp-env:
	scp ./env.sh isu11:/home/isucon/env.sh & \
	scp ./env.sh isu12:/home/isucon/env.sh & \
	scp ./env.sh isu13:/home/isucon/env.sh & \
	wait

restart:
	ssh isu11 "sudo systemctl restart $(APP)-go.service" & \
	ssh isu12 "sudo systemctl restart $(APP)-go.service" & \
	ssh isu13 "sudo systemctl restart $(APP)-go.service" & \
	wait

stop:
	ssh isu11 "sudo systemctl stop $(APP)-go.service" & \
	ssh isu12 "sudo systemctl stop $(APP)-go.service" & \
	ssh isu13 "sudo systemctl stop $(APP)-go.service" & \
	wait

start:
	ssh isu11 "sudo systemctl start $(APP)-go.service" & \
	ssh isu12 "sudo systemctl start $(APP)-go.service" & \
	ssh isu13 "sudo systemctl start $(APP)-go.service" & \
	wait

