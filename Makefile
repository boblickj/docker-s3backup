.PHONY: build
build:
	docker build -t boblickj/s3backup .

.PHONY: clean
clean:
	docker rmi -f boblickj/s3backup
