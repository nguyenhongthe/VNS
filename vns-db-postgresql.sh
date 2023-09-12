#!/bin/bash
#==============================================================================================================
# Tên tập lệnh: vns-db-postgreslq.sh
# Mô tả: Quản lý cơ sở dữ liệu PostgreSQL.
# Tác giả: Nguyễn Hồng Thế <nguyenhongthe.net>
# Ngày: 2023-08-25
# Phiên bản: 1.0.3
# Giấy phép: Giấy phép MIT
# Sử dụng: curl -sO https://vnscdn.comvns-db-postgresql.sh && chmod +x vns-db-postgresql.sh && bash vns-db-postgresql.sh
#==============================================================================================================

# PostgreSQL Database Management Script

DEFAULT_HOST="localhost"  # Giá trị mặc định cho host PostgreSQL
DEFAULT_PORT="5432"  # Giá trị mặc định cho cổng PostgreSQL

print_usage() {
    echo "Sử dụng: $0 [Tùy chọn]"
    echo "Tùy chọn:"
    echo "  -h, --help           Hiển thị hướng dẫn sử dụng"
    echo "  -u, --create-user    Tạo người dùng PostgreSQL và cơ sở dữ liệu tương ứng"
    echo "  -e, --empty-schema   Làm rỗng và tạo lại schema"
    echo "  -i, --import-db      Import cơ sở dữ liệu từ file"
    echo "  -x, --export-db      Export cơ sở dữ liệu ra file"
    exit 0
}

if [[ $# -eq 0 ]]; then
    print_usage
fi

while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -h|--help)
            print_usage
            shift
            ;;
        -u|--create-user)
            create_user=true
            shift
            ;;
        -e|--empty-schema)
            empty_schema=true
            shift
            ;;
        -i|--import-db)
            import_db=true
            shift
            ;;
        -x|--export-db)
            export_db=true
            shift
            ;;
        *)
            echo "Tùy chọn không hợp lệ: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Nhập thông tin cấu hình của PostgreSQL
read -p "Nhập host của PostgreSQL (mặc định: $DEFAULT_HOST): " host
host=${host:-"$DEFAULT_HOST"}

read -p "Nhập cổng PostgreSQL (mặc định: $DEFAULT_PORT): " port
port=${port:-"$DEFAULT_PORT"}

# Tạo người dùng và cơ sở dữ liệu mới
if [ "$create_user" = true ]; then
    read -p "Nhập tên người dùng PostgreSQL (admin): " admin_user
    admin_user=${admin_user:-"admin"}

    read -s -p "Nhập mật khẩu PostgreSQL cho người dùng $admin_user: " admin_password
    echo

    read -p "Nhập tên người dùng mới: " new_user
    read -s -p "Nhập mật khẩu cho người dùng $new_user: " new_user_password
    echo
    read -p "Nhập tên cơ sở dữ liệu mới cho người dùng $new_user: " new_database

    # Tạo người dùng
    sudo -u postgres psql -h "$host" -p "$port" -U "$admin_user" -c "CREATE USER $new_user WITH ENCRYPTED PASSWORD '$new_user_password';"

    # Tạo cơ sở dữ liệu và gán quyền cho người dùng
    sudo -u postgres psql -h "$host" -p "$port" -U "$admin_user" -c "CREATE DATABASE $new_database OWNER $new_user;"

    # Gán quyền truy cập vào cơ sở dữ liệu
    sudo -u postgres psql -h "$host" -p "$port" -U "$admin_user" -d "$new_database" -c "GRANT CONNECT ON DATABASE $new_database TO $new_user;"

    # Gán quyền truy cập vào schema public
    sudo -u postgres psql -h "$host" -p "$port" -U "$admin_user" -d "$new_database" -c "GRANT USAGE ON SCHEMA public TO $new_user;"

    # Gán quyền truy cập vào các bảng trong schema public
    sudo -u postgres psql -h "$host" -p "$port" -U "$admin_user" -d "$new_database" -c "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO $new_user;"

    # Gán quyền truy cập vào các sequence trong schema public (nếu có)
    sudo -u postgres psql -h "$host" -p "$port" -U "$admin_user" -d "$new_database" -c "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO $new_user;"

    # Gán quyền truy cập vào các function trong schema public (nếu có)
    sudo -u postgres psql -h "$host" -p "$port" -U "$admin_user" -d "$new_database" -c "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO $new_user;"
fi

# Làm rỗng và tạo lại schema
if [ "$empty_schema" = true ]; then
    read -p "Nhập tên người dùng PostgreSQL: " user
    read -p "Nhập tên cơ sở dữ liệu PostgreSQL: " database
    read -s -p "Nhập mật khẩu PostgreSQL: " password
    echo

    PGPASSWORD="$password" psql -U "$user" -h "$host" -p "$port" -d "$database" -c "DROP SCHEMA public CASCADE;"
    PGPASSWORD="$password" psql -U "$user" -h "$host" -p "$port" -d "$database" -c "CREATE SCHEMA public;"

    if [ $? -eq 0 ]; then
        echo "Xóa và tạo lại schema thành công"
    else
        echo "Lỗi khi xóa hoặc tạo lại schema"
    fi
fi

# Import cơ sở dữ liệu từ file
if [ "$import_db" = true ]; then
    read -p "Nhập tên người dùng PostgreSQL: " user
    read -p "Nhập tên cơ sở dữ liệu PostgreSQL: " database
    read -s -p "Nhập mật khẩu PostgreSQL: " password
    echo
    read -p "Nhập đường dẫn tới file cơ sở dữ liệu để import: " import_file

    PGPASSWORD="$password" pg_restore -U "$user" -h "$host" -p "$port" -d "$database" "$import_file"
    if [ $? -eq 0 ]; then
        echo "Import cơ sở dữ liệu thành công"
    else
        echo "Lỗi khi import cơ sở dữ liệu"
    fi
fi

# Export cơ sở dữ liệu ra file
if [ "$export_db" = true ]; then
    read -p "Nhập tên người dùng PostgreSQL: " user
    read -p "Nhập tên cơ sở dữ liệu PostgreSQL: " database
    read -s -p "Nhập mật khẩu PostgreSQL: " password
    echo
    read -p "Nhập đường dẫn tới file để export cơ sở dữ liệu: " export_file

    PGPASSWORD="$password" pg_dump -U "$user" -h "$host" -p "$port" -Fc "$database" > "$export_file"
    if [ $? -eq 0 ]; then
        echo "Export cơ sở dữ liệu thành công"
    else
        echo "Lỗi khi export cơ sở dữ liệu"
    fi
fi