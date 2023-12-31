#!/bin/bash
#=======================================================================================================================
# Tên tập lệnh: vns-web-debian.sh
# Mô tả: Tạo user để chạy web tương thích với Python và Next.js thông qua proxy NGINX trên hệ điều hành Debian.
# Tác giả: Nguyễn Hồng Thế <nguyenhongthe.net>
# Ngày: 2023-09-12
# Phiên bản: 1.0.1
# Giấy phép: Giấy phép MIT
# Sử dụng: curl -sO https://vnscdn.com/platforms/vns-web-debian.sh && chmod +x vns-web-debian.sh && bash vns-web-debian.sh
#=======================================================================================================================

# Hàm tạo thư mục cho user
create_user_directory() {
    local user="$1"
    local directory="$2"

    echo "Tạo thư mục $directory tại /home/$user/$directory thành công. Để lưu trữ các file $directory."
    su - "$user" -c "mkdir -p ~/$directory"
}

# Tạo user
echo "Tạo user"
read -p "Nhập tên user: " username
adduser "$username"

# Chuyển sang user vừa tạo và chạy Zsh
echo "Chuyển sang user vừa tạo và chạy Zsh..."
su - "$username" -c "curl -L http://install.ohmyz.sh | sh && exec zsh -c > /dev/null && chsh -s $(which zsh) > /dev/null"
echo

# Tạo các thư mục cần thiết
echo "Tạo các thư mục cần thiết..."
echo
create_user_directory "$username" "configs"
echo
create_user_directory "$username" "logs"
echo
create_user_directory "$username" "commands"
echo
create_user_directory "$username" "www"
echo
create_user_directory "$username" "nextjs"
echo
create_user_directory "$username" "ssl"
echo
echo "Cấu hình cơ bản cho user $username đã hoàn tất."
echo
# Thoát khỏi user vừa tạo
echo "Thoát khỏi user vừa tạo..."
