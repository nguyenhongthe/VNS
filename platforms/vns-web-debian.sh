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

# Hàm tạo thư mục cho user
create_user_directory() {
    local user="$1"
    local directory="$2"

    echo "Tạo thư mục $directory thành công. Để lưu trữ các file $directory."
    su - "$user" -c "mkdir -p ~/$directory"
}

# Tạo user
echo "Tạo user"
read -p "Nhập tên user: " username
adduser "$username"

# Chuyển sang user vừa tạo và chạy Zsh
echo "Chuyển sang user vừa tạo và chạy Zsh..."
su - "$username" -c "curl -L http://install.ohmyz.sh | sh && exec zsh &"
echo

# Tạo các thư mục cần thiết
echo "Tạo các thư mục cần thiết..."
create_user_directory "$username" "configs"
create_user_directory "$username" "logs"
create_user_directory "$username" "commands"
create_user_directory "$username" "www"
create_user_directory "$username" "nextjs"
create_user_directory "$username" "ssl"

echo "Cấu hình cơ bản cho user $username đã hoàn tất."
echo
