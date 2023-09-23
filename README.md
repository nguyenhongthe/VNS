# VNS Script

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.md)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://vnscdn.com/)

## Mô tả

VNS Script là một tập lệnh dùng để xây dựng máy chủ chạy web tương thích với Python và Next.js cho hệ điều hành Linux. Tập lệnh này hỗ trợ cài đặt và cập nhật các thành phần như Python, Node.js, Yarn, PostgreSQL, Nginx, Supervisord và các công cụ hữu ích khác.

## Cách sử dụng

Bạn có thể sử dụng các lệnh sau để tải về và chạy VNS Script:

### Sử dụng Curl

```bash
curl -sO https://vnscdn.com/vns.sh && chmod +x vns.sh && bash vns.sh
```

### Sử dụng Wget
  
  ```bash
  wget https://vnscdn.com/vns.sh -O ~/vns.sh && chmod +x ~/vns.sh && bash ~/vns.sh
  ```

## Tùy chọn

- `info`: Hiển thị thông tin script.
- `-h, --help`: Hiển thị hướng dẫn sử dụng.
- `check-update`: Kiểm tra và cập nhật VNS Script và script cài đặt cho hệ điều hành.

## Cron job tự động kiểm tra câp nhật

Script tự động tạo một cron job để kiểm tra cập nhật VNS Script và script cài đặt cho hệ điều hành bằng cách thêm dòng sau vào crontab:

```bash
@reboot bash ~/vns.sh check-update
```

Hoặc bạn có thể tự kiểm tra cập nhật bằng cách chạy thủ công lệnh sau:

```bash
bash ~/vns.sh check-update
```

## Đóng góp và báo lỗi

Nếu bạn gặp lỗi khi sử dụng VNS Script, vui lòng tạo một issue mới tại [đây](https://github.com/nguyenhongthe/VNS/issues) hoặc gửi pull request để đóng góp cho dự án.

## Bản quyền và giấy phép

Copyright (c) 2013-2023 Nguyễn Hồng Thế Blog - Phát hành theo giấy phép [MIT](LICENSE).
