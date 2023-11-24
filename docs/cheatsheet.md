# カンペ
## .ssh/config の設定
     Host isucon-bastion
       HostName <指示された踏み台サーバ>
       User <指示されたユーザー名>
    
     Host isucon-server
       ProxyJump isucon-bastion
       HostName <指示されたインスタンスのアドレス>
       LocalForward localhost:10443 localhost:443
## 最初に入れるツール

    sudo apt update
    sudo apt install -y unzip iotop percona-toolkit dstat htop
    curl -L https://github.com/tkuchiki/alp/releases/download/v1.0.10/alp_linux_amd64.tar.gz | tar xvzf -
    sudo cp alp /usr/local/bin/alp
    git clone https://github.com/kazeburo/query-digester.git && sudo install ./query-digester/query-digester /usr/local/bin

## alp

**nginx の設定**

```nginx
# server の外側に
# https://github.com/tkuchiki/alp/blob/master/README.ja.md#log-format
log_format ltsv "time:$time_local"
                "\thost:$remote_addr"
                "\tforwardedfor:$http_x_forwarded_for"
                "\treq:$request"
                "\tstatus:$status"
                "\tmethod:$request_method"
                "\turi:$request_uri"
                "\tsize:$body_bytes_sent"
                "\treferer:$http_referer"
                "\tua:$http_user_agent"
                "\treqtime:$request_time"
                "\tcache:$upstream_http_x_cache"
                "\truntime:$upstream_http_x_runtime"
                "\tapptime:$upstream_response_time"
                "\tvhost:$host";
```

```nginx
server {
  ...
  access_log /var/log/nginx/access_log.ltsv ltsv;
}
```

**解析**

    alp ltsv --file /var/log/nginx/access_log.ltsv -m '/items/.*,/users/.*,/new_items/.*,/transactions/.*' --sort sum --reverse | head
- `-m` に正規表現をカンマ区切りで渡すとURLでいい感じにまとめてくれる
- `--sort` には `sum` とか`p50` とか`count`とかつかうといいのでは
- https://gist.github.com/motemen/fcd59e24403fb5f2e811ecdaae9e45ef by motemen

## ソースコードのコピー

```
mkdir -p webapp
scp -Cr isu01:webapp/go webapp/go
git clean -nX webapp/go # ischolar みたいなバイナリを消す
git clean -fX webapp/go
```
```
scp -Cr isu01:webapp/sql webapp/sql
```

```
scp -Cr isu01:env.sh .
```

```
mkdir -p ./etc/nginx && scp isu01:/etc/nginx/sites-available/isucholar.conf ./etc/nginx/sites-available/isucholar.conf
mkdir -p ./etc/nginx/sites-available && scp isu01:/etc/nginx/sites-available/isucholar.conf ./etc/nginx/sites-available/isucholar.conf
```

## pprof

```go
import _ "net/http/pprof"


go func() {
	log.Println(http.ListenAndServe(":6060", nil))
}()
```

こうした上で

    go tool pprof -seconds 120 -http=:9999 http://target:6060

とかすると 120s 後にブラウザでなんらか開かれる。のでその間にベンチ回す。Flame Graph もある！

おそらく `target:6060` にポートフォワードが必要なので、なんか面倒そうだったらホストの中で

とかして手元に持ってきて

    go tool pprof -http=:9999 prof.out

とかしたらよさそう。


## systemd
- `/etc/systemd/system/` になんかある
- `sudo service isucari.golang restart` みたいなことしたら起動
- `journalctl -f -u isucari.golang` でログ見れる
- デーモン化する & 再起動に耐えられるようにするときに良くこういうの使う
    - `sudo systemctl daemon-reload`
    - `sudo systemctl enable isucari.golang`
    - `sudo systemctl start isucari.golang`


## sqlx で WHERE IN

```go
sql := `SELECT * FROM users WHERE id IN (?)`

sql, params, err := sqlx.In(sql, []int{1,2,3,4,5})
if err != nil {
	log.Fatal(err)
}

var users []User
if err := sqlx.Select(&users, sql, params...); err != nil {
	log.Fatal(err)
}
```

## Redis (redigo)

```go
import "github.com/gomodule/redigo/redis"
```

```go
var pool *redis.Pool

func main() {
	pool = &redis.Pool{
		Dial: func() (redis.Conn, error) {
			return redis.DialURL(os.Getenv("REDIS_ADDR"))
		},
	}
}
```

```go
	conn := pool.Get()
	defer conn.Close()

	for _, isu := range isuList {
		result, err := redis.Strings(conn.Do("ZREVRANGEBYSCORE", isu.condRedisKey(), "+inf", "0", "WITHSCORES", "LIMIT", "0", "1"))
```

## スローログ有効にする

そのセッションのみ

```
SET GLOBAL slow_query_log = 1;
SET GLOBAL slow_query_log_file = "/var/log/mysql/mysql-slow.log";
SET GLOBAL long_query_time = 0;
```

```
pt-query-digset /var/log/mysql/mysql-low.log
```

## query-digester のほうがいいかもしれん

```
git clone https://github.com/kazeburo/query-digester.git && sudo install ./query-digester/query-digester /usr/local/bin
```
```
sudo query-digester -duration 120
```

# 何も考えずにやっていいやつ

* interpolateParams=true
* go-json
  * `import "github.com/goccy/go-json"`
  * https://github.com/fujiwara/isucon11-f/pull/9/files