#!/bin/bash
#==============================================================================================================
# Tên tập lệnh: vns-db-postgreslq.sh
# Mô tả: Quản lý cơ sở dữ liệu PostgreSQL.
# Tác giả: Nguyễn Hồng Thế <nguyenhongthe.net>
# Ngày: 2023-09-22
# Phiên bản: 1.0.10
# Giấy phép: Giấy phép MIT
# Sử dụng: curl -sO https://vnscdn.com/vns-db-postgresql.sh && chmod +x vns-db-postgresql.sh && bash vns-db-postgresql.sh
#==============================================================================================================

# PostgreSQL Database Management Script

host="localhost"  # Giá trị mặc định cho host PostgreSQL
port="5432"  # Giá trị mặc định cho cổng PostgreSQL

print_usage() {
    echo "Sử dụng: $0 [Tùy chọn]"
    echo "Tùy chọn:"
    echo "  info, --info            Hiển thị thông tin về script"
    echo "  -h, --help              Hiển thị hướng dẫn sử dụng"
    echo "  -u, --create-user       Tạo người dùng PostgreSQL và cơ sở dữ liệu tương ứng"
    echo "  -d, --delete-user       Xóa người dùng PostgreSQL và cơ sở dữ liệu tương ứng"
    echo "  -e, --empty-schema      Làm rỗng và tạo lại schema"
    echo "  -i, --import-db         Import cơ sở dữ liệu từ file"
    echo "  -x, --export-db         Export cơ sở dữ liệu ra file"
    echo "  -p, --change-password   Đổi mật khẩu cho người dùng postgres"
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
        info|--info)
            info=true
            shift
            ;;
        -u|--create-user)
            create_user=true
            shift
            ;;
        -d|--delete-user)
            delete_user=true
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
        -p|--change-password)
            change_postgres_password=true
            shift
            ;;
        *)
            echo "Tùy chọn không hợp lệ: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Thay đổi mật khẩu cho người dùng postgres
if [ "$change_postgres_password" = true ]; then
    echo
    # Nhập tên người dùng cần đổi mật khẩu
    read -p "Nhập tên người dùng cần đổi mật khẩu (mặc định là postgres): " postgres_user
    if [ -z "$postgres_user" ]; then
        postgres_user="postgres"
    fi
    read -s -p "Nhập mật khẩu mới cho người dùng postgres: " postgres_new_password
    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$postgres_new_password';"
    if [ $? -eq 0 ]; then
        echo "Đổi mật khẩu cho người dùng postgres thành công"
    else
        echo "Lỗi khi đổi mật khẩu cho người dùng postgres"
    fi
fi

# Tạo người dùng và cơ sở dữ liệu mới
if [ "$create_user" = true ]; then
    # Nhập mật khẩu cho người dùng postgres
    echo
    read -s -p "Nhập mật khẩu cho người dùng postgres: " postgres_password
    echo
    read -p "Nhập tên người dùng mới: " new_user
    echo
    read -s -p "Nhập mật khẩu cho người dùng $new_user: " new_user_password
    echo
    read -p "Nhập tên cơ sở dữ liệu mới cho người dùng $new_user: " new_database
    echo

    # Tạo người dùng sử dụng PGPASSWORD
    PGPASSWORD="$postgres_password" psql -U postgres -h "$host" -p "$port" -c "CREATE USER $new_user WITH ENCRYPTED PASSWORD '$new_user_password';"

    # Tạo cơ sở dữ liệu và gán quyền cho người dùng
    PGPASSWORD="$postgres_password" psql -U postgres -h "$host" -p "$port" -c "CREATE DATABASE $new_database OWNER $new_user;"

    # Gán quyền truy cập vào cơ sở dữ liệu
    PGPASSWORD="$postgres_password" psql -U postgres -h "$host" -p "$port" -d "$new_database" -c "GRANT CONNECT ON DATABASE $new_database TO $new_user;"

    # Gán quyền sở hữu vào schema public
    PGPASSWORD="$postgres_password" psql -U postgres -h "$host" -p "$port" -d "$new_database" -c "ALTER SCHEMA public OWNER TO $new_user;"
    PGPASSWORD="$postgres_password" psql -U postgres -h "$host" -p "$port" -d "$new_database" -c "GRANT ALL ON SCHEMA public TO $new_user;"
    unset PGPASSWORD

    if [ $? -eq 0 ]; then
        echo "Tạo người dùng và cơ sở dữ liệu thành công"
    else
        echo "Lỗi khi tạo người dùng và cơ sở dữ liệu"
    fi
fi

# Xóa người dùng và cơ sở dữ liệu
if [ "$delete_user" = true ]; then
    echo
    read -s -p "Nhập mật khẩu PostgreSQL của người dùng quản trị postgres: " postgres_password
    echo
    echo
    echo -e "\e[1;31mBạn đang thực hiện thao tác xóa người dùng và cơ sở dữ liệu PostgreSQL\e[0m"
    echo
    echo -e "\e[1;31mHÃY THAO TÁC CẨN THẬN!\e[0m"
    echo
    read -p "Nhập tên người dùng PostgreSQL cần xóa: " user
    read -p "Nhập tên cơ sở dữ liệu PostgreSQL cần xóa: " database
    echo

    PGPASSWORD="$postgres_password" psql -U postgres -h "$host" -p "$port" -c "DROP DATABASE $database;"
    PGPASSWORD="$postgres_password" psql -U postgres -h "$host" -p "$port" -c "DROP USER $user;"
    unset PGPASSWORD

    if [ $? -eq 0 ]; then
        echo "Xóa người dùng và cơ sở dữ liệu thành công"
    else
        echo "Lỗi khi xóa người dùng và cơ sở dữ liệu"
    fi
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

# Script Info
if [ "$info" = true ]; then
    echo
    echo "================================================================"
    echo "  -   Quản lý cơ sở dữ liệu PostgreSQL."
    echo "  -   Phiên bản: 1.0.10"
    echo "  -   Ngày: 22-09-2023"
    echo "  -   Tác giả: Nguyễn Hồng Thế <nguyenhongthe.net>"
    echo "  -   Giấy phép: MIT License"
    echo "================================================================"
    echo
fi

