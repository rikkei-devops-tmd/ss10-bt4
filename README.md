BAI 4: THIET LAP CUSTOM NETWORK VA NAMED VOLUME BANG DOCKER CLI

1. MUC TIEU VA BOI CANH

1.1. Boi canh
Trong mo hinh kien truc da container, cac dich vu (Services) can co co che giao tiep mang noi bo an toan thong qua co che phan giai ten mien tu dong (DNS Resolution) va co co che luu tru du lieu ben vung (Data Persistence) doc lap voi vong doi cua container. Bai tap nay thuc hien ket noi Backend API va PostgreSQL Database bang Docker CLI thu cong.

1.2. Muc tieu ky thuat
- Khoi tao Custom Bridge Network co ten app-net de phan giai DNS noi bo qua container name.
- Khoi tao Named Volume co ten db-data de luu tru du lieu co so du lieu ben vung.
- Khoi chay container Database (postgres:15-alpine) va Backend (hw-backend:v1) ket noi chung vao app-net.
- Kiem tra co che phan giai DNS giua cac container trong cung custom network.
- Thuc nghiem kiem chung tinh ben vung cua du lieu (Data Persistence) khi xoa va tao moi container Database.

2. CO CHE CUSTOM BRIDGE NETWORK VA NAMED VOLUME

2.1. Phan biet Default Bridge Network va Custom Bridge Network
- Default Bridge Network: La mang bridge mac dinh (bridge) duoc Docker tu dong tao ra khi cai dat. Cac container trong default bridge khong the giao tiep voi nhau qua ten container (hostname) ma bat buoc phai dung dia chi IP hoac dung flag legacy --link.
- Custom Bridge Network: La mang do nguoi dung tu dinh nghia bang lenh docker network create. Docker tu dong tich hop Embedded DNS Server tai dia chi 127.0.0.11 ben trong network namespace cua container, cho phep cac container tu dong phan giai ten goi cua nhau (Service Discovery / DNS Resolution) thanh dia chi IP noi bo ma khong can hardcode IP.

2.2. Phan biet cac co che luu tru du lieu trong Docker
- Anonymous Volume: Volume khong duoc dat ten ro rang (chi co chuoi hash ngau nhien), kho quan ly va de bi xoa bo khi container bi go bo.
- Named Volume: Volume duoc dat ten tuong minh (vi du db-data) va do Docker Engine quan ly tai thu muc luu tru tap trung (/var/lib/docker/volumes/). Named Volume co vong doi hoan toan doc lap voi container, du lieu ton tai vinh vien cho den khi bi xoa chu dong bang docker volume rm.
- Bind Mount: Gan truc tiep mot thu muc tu Host OS vao container. Phu hop cho qua trinh development de dong bo source code, nhung phu thuoc chat che vao he thong file cua may chu Host.

3. CAC LENH THUC THI VA QUY TRINH KIEM TRA

3.1. Tao Custom Bridge Network va Named Volume
Lenh thuc thi:
```bash
docker network create --driver bridge app-net
docker volume create db-data
```

3.2. Khoi chay Database Container va Backend Container
Lenh thuc thi:
```bash
docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  postgres:15-alpine

docker run -d \
  --name app-container \
  --network app-net \
  -p 8080:3000 \
  -e DB_HOST=db-server \
  -e DB_PORT=5432 \
  -e DB_NAME=mydb \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  hw-backend:v1
```

3.3. Kiem tra Network va phan giai DNS noi bo
Lenh thuc thi:
```bash
docker network ls | grep app-net
docker volume ls | grep db-data
docker network inspect app-net
```
Ket qua kiem tra ket noi mang giua backend va database:
```bash
docker exec -i app-container nc -zv db-server 5432
```
Ket qua dau ra:
```text
db-server (172.18.0.2:5432) open
```

3.4. Kiem chung tinh ben vung du lieu (Data Persistence Test)
Buoc 1: Tao bang va them du lieu mau vao DB
```bash
docker exec -i db-server psql -U postgres -d mydb -c "CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(50)); INSERT INTO users (name) VALUES ('Alice'), ('Bob');"
docker exec -i db-server psql -U postgres -d mydb -c "SELECT * FROM users;"
```
Ket qua truy van:
```text
 id | name  
----+-------
  1 | Alice
  2 | Bob
(2 rows)
```

Buoc 2: Xoa cuong buc container db-server
```bash
docker rm -f db-server
```

Buoc 3: Khoi chay container db-server moi gan cung Named Volume db-data
```bash
docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  postgres:15-alpine
```

Buoc 4: Kiem tra lai du lieu tren container moi
```bash
docker exec -i db-server psql -U postgres -d mydb -c "SELECT * FROM users;"
```
Ket qua truy van xac nhan du lieu con nguyen ven:
```text
 id | name  
----+-------
  1 | Alice
  2 | Bob
(2 rows)
```

4. KET LUAN

Custom Bridge Network giup cac dich vu ket noi va phan giai ten mien noi bo de dang qua DNS, trong khi Named Volume dam bao toan ven du lieu co so du lieu khong bi mat khi container gap su co hoac duoc nang cap/khoi tao lai.
