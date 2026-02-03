# Build Dict

Các công cụ để chuẩn bị dữ liệu văn bản và xử lý nó bằng Gemini API.

## Cài đặt

Đảm bảo bạn đã cài đặt [Crystal](https://crystal-lang.org/install/).

1.  Clone repository này.
2.  Cài đặt các thư viện phụ thuộc (nếu có):
    ```sh
    shards install
    ```

## Build (Xây dựng)

Để build các file thực thi `prepare-data` và `call-gemini`, chạy lệnh:

```sh
shards build --release
```

Sau khi build, các file binary sẽ nằm trong thư mục `bin/`.

## Cấu hình

Trước khi chạy `call-gemini`, bạn cần tạo một file `config.yml` ở thư mục gốc.

Ví dụ **config.yml**:

```yaml
endpoint: 'http://localhost:8045' # antigravity-tools
api_key: 'your_api_key_here'
model: 'gemini-3-pro-low' # Các tùy chọn: gemini-3-flash, gemini-3-pro-high, gemini-3-pro-low, gemini-2.5-flash
conns: 3 # số lượng kết nối đồng thời
```

## Hướng dẫn sử dụng

### 1. Prepare Data (Chuẩn bị dữ liệu)

Công cụ `prepare-data` chia một file văn bản đầu vào lớn thành các phần nhỏ hơn để xử lý.

**Cú pháp:**

```sh
./bin/prepare-data <file_đầu_vào> <folder_đầu_ra>
```

**Ví dụ:**

```sh
./bin/prepare-data raw_text.txt data/my_dataset
```

Lệnh này sẽ tạo thư mục `data/my_dataset/` và điền vào đó các file văn bản đã chia nhỏ (ví dụ: `0.zh.txt`, `1.zh.txt`, ...).

### 2. Call Gemini (Gọi Gemini)

Công cụ `call-gemini` xử lý các phần dữ liệu đã chuẩn bị bằng cách sử dụng model API đã cấu hình.

**Cú pháp:**

```sh
./bin/call-gemini <folder_dữ_liệu>
```

**Ví dụ:**

```sh
./bin/call-gemini data/my_dataset
```

Lệnh này sẽ:

1.  Đọc các file từ `data/my_dataset/*.zh.txt`.
2.  Gửi nội dung đến API.
3.  Lưu phản hồi vào cùng thư mục với phần mở rộng mới dựa trên model (ví dụ: `.3pl.json` cho `gemini-3-pro-low`).

Bạn cũng có thể xử lý nhiều bộ dữ liệu cùng lúc:

```sh
./bin/call-gemini dataset1 dataset2
```
