#!/bin/bash
#=======================================================================================================================
# Tên tập lệnh: vns-web-debian.sh
# Mô tả: Tạo user để chạy web tương thích với Python và Next.js thông qua proxy NGINX trên hệ điều hành Debian.
# Tác giả: Nguyễn Hồng Thế <nguyenhongthe.net>
# Ngày: 2023-08-25
# Phiên bản: 1.0.0
# Giấy phép: Giấy phép MIT
# Sử dụng: curl -sO https://vnscdn.com/platforms/vns-web-debian.sh && chmod +x vns-web-debian.sh && bash vns-web-debian.sh
#=======================================================================================================================

# Tạo user
echo "Tạo user"
read -p "Nhập tên user: " username
adduser $username

# Chuyển sang user vừa tạo và chạy Zsh
echo "Chuyển sang user vừa tạo và chạy Zsh..."
su - $username -c "curl -L http://install.ohmyz.sh | sh && exec zsh"
echo

# Tạo các thư mục cần thiết
echo "Tạo các thư mục cần thiết..."
mkdir -p ~/configs
echo "Tạo thư mục ~/configs thành công."
mkdir -p ~/logs
echo "Tạo thư mục ~/logs thành công."
mkdir -p ~/commands
echo "Tạo thư mục ~/commands thành công."
mkdir -p ~/www
echo "Tạo thư mục ~/www thành công."
mkdir -p ~/nextjs
echo "Tạo thư mục ~/nextjs thành công."
mkdir -p ~/ssl
echo "Tạo thư mục ~/ssl thành công."

echo "Cấu hình cơ bản cho user $username đã hoàn tất."
echo
