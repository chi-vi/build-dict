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
./bin/call-gemini [options] <folder_dữ_liệu> [folder_dữ_liệu...]
```

**Options:**

| Option | Mô tả | Mặc định |
|--------|-------|----------|
| `-c PATH` | Đường dẫn đến file config YAML | `config.yml` |
| `-w CONNS` | Số lượng kết nối đồng thời | `3` |
| `-m MODEL` | Model sử dụng | `gemini-3-pro-low` |
| `-t TEMPERATURE` | Giá trị temperature | `0.4` |
| `-r REASONING_LEVEL` | Mức độ reasoning | `minimal` |
| `-f MIN` | Chỉ số file tối thiểu để xử lý | `0` |
| `-u MAX` | Chỉ số file tối đa để xử lý (-1 = không giới hạn) | `-1` |

**Các model được hỗ trợ:**

- `gemini-3-flash` → `.3ft.json`
- `gemini-3-pro-high` → `.3ph.json`
- `gemini-3-pro-low` → `.3pl.json`
- `gemini-2.5-flash` → `.25f.json`

**Ví dụ:**

```sh
# Xử lý với cấu hình mặc định
./bin/call-gemini data/my_dataset

# Xử lý với model khác và nhiều kết nối hơn
./bin/call-gemini -m gemini-3-flash -w 5 data/my_dataset

# Xử lý một phạm vi file cụ thể (từ file 10 đến 20)
./bin/call-gemini -f 10 -u 20 data/my_dataset

# Sử dụng file config khác
./bin/call-gemini -c custom_config.yml data/my_dataset

# Xử lý nhiều bộ dữ liệu cùng lúc
./bin/call-gemini dataset1 dataset2
```

Lệnh này sẽ:

1.  Đọc các file từ `<folder>/*.zh.txt`.
2.  Gửi nội dung đến API.
3.  Lưu phản hồi vào cùng thư mục với phần mở rộng mới dựa trên model.
