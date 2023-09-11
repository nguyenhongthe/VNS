#!/bin/bash
#==============================================================================================================
# Tên tập lệnh: VNS Script
# Mô tả: Xây dựng máy chủ chạy web tương thích với Python và Next.js cho Linux.
# Tác giả: Nguyễn Hồng Thế <nguyenhongthe.net>
# Ngày: 2023-08-25
# Phiên bản: 1.0.0
# Giấy phép: Giấy phép MIT
# Sử dụng: curl -sO https://vnscdn.com/vns.sh && chmod +x vns.sh && bash vns.sh
# Hoặc: wget https://vnscdn.com/vns.sh -O ~/vns.sh && chmod +x ~/vns.sh && bash ~/vns.sh
#==============================================================================================================

vns_version="1.0.0"
vns_debian_version="1.0.1"
vns_ubuntu_version="1.0.0"
vns_amazon_version="1.0.0"
vns_rhel_version="1.0.0"
vns_website_version="1.0.0"
script_url="https://vnscdn.com/"

# Kiểm tra xem script có được chạy bởi root hay không?
if [ "x$(id -u)" != 'x0' ]; then
    echo 'Bạn cần chạy script này với quyền root'
    exit 1
fi

# Ngó coi thử đang chạy trên hệ điều hành nào.
case $(head -n1 /etc/issue | cut -f 1 -d ' ') in
    Debian)     type="debian" ;;
    Ubuntu)     type="ubuntu" ;;
    Amazon)     type="amazon" ;;
    *)          type="rhel" ;;
esac

# Kiểm tra xem hệ thống đã cài đặt wget hay curl chưa? Nếu chưa thì cài đặt.
if [ ! -e '/usr/bin/wget' ] && [ ! -e '/usr/bin/curl' ]; then
    echo "Cài đặt wget hoặc curl..."
    if [ "$type" == "debian" ] || [ "$type" == "ubuntu" ]; then
        apt-get update -y
        apt-get install -y wget curl
    elif [ "$type" == "amazon" ]; then
        yum update -y
        yum install -y wget curl
    elif [ "$type" == "rhel" ]; then
        dnf update -y
        dnf install -y wget curl
    fi
fi

# Hàm in ra changelog của phiên bản mới của VNS Script (nếu có)
function print_changelog {
    latest_changelog=$(curl -s "https://vnscdn.com/changelog-latest.txt")
    if [ ! -z "$latest_changelog" ]; then
        echo "Changelog của phiên bản mới nhất của VNS Script:"
        echo "$latest_changelog"
        echo "Xem changelog đầy đủ trên trình duyệt: https://vnscdn.com/changelog.txt"
    else
        echo "Không có thông tin changelog cho phiên bản mới."
    fi
}

# Hàm in ra changelog của phiên bản mới của script cài đặt cho hệ điều hành (nếu có)
function print_platform_changelog {
    latest_platform_changelog=$(curl -s "https://vnscdn.com/platforms/changelog-$type-latest.txt")
    if [ ! -z "$latest_platform_changelog" ]; then
        echo "Changelog của phiên bản mới dành cho $type:"
        echo "$latest_platform_changelog"
        echo "Xem changelog đầy đủ trên trình duyệt: https://vnscdn.com/platforms/changelog-$type.txt"
    else
        echo "Không có thông tin changelog cho phiên bản mới của $type."
    fi
}

# Thư mục để chứa script.
update_script_dir=~

# Thêm cron job kiểm tra cập nhật vào crontab.
# Chạy mỗi lần khởi động hệ thống.
function add_update_check_cron {
    echo "Thêm cron job kiểm tra cập nhật vào crontab..."
    echo 
    # Kiểm tra xem cron job đã tồn tại chưa? Nếu chưa thì thêm vào. Nếu có rồi thì té.
    if ! crontab -l | grep -q 'bash ~/vns.sh check-update'; then
        (crontab -l ; echo "@reboot bash ~/vns.sh check-update") | crontab -
    fi
}

# Hàm kiểm tra và tải về script cài đặt cho hệ điều hành.
function check_and_update_platform_script {
    # Kiểm tra xem script cài đặt cho hệ điều hành đã tồn tại chưa? Nếu chưa thì tải về và cài đặt.
    if [ ! -e "$update_script_dir/vns-$type.sh" ]; then
        echo "Tải về script cài đặt cho hệ điều hành $type..."
        echo
        wget "https://vnscdn.com/platforms/vns-$type.sh" -O "$update_script_dir/vns-$type.sh"
        if [ "$?" -eq '0' ]; then
            chmod +x "$update_script_dir/vns-$type.sh"
            bash "$update_script_dir/vns-$type.sh" "$*"
            add_update_check_cron
            exit
        else
            echo "Lỗi trong quá trình tải về và cài đặt."
            echo
            exit 1
        fi
    # Ngược lại thì kiểm tra xem phiên bản hiện tại của script cài đặt cho hệ điều hành có khác phiên bản mới nhất hay không?
    else
        # Lấy phiên bản mới nhất của script cài đặt cho hệ điều hành từ repo của VNSCDN.
        latest_version_platform=$(curl -s "https://vnscdn.com/platforms/latest-version-$type.txt")
        # Lấy phiên bản hiện tại của script cài đặt cho hệ điều hành.
        current_version_platform=$(grep -oE "vns_${type}_version=\"([0-9.]+)\"" "$update_script_dir/vns-$type.sh" | cut -d '"' -f 2)
        echo "Script cài đặt cho hệ điều hành $type đã được cài đặt."
        echo
        echo "Phiên bản hiện tại của script cài đặt cho hệ điều hành là $type: $current_version_platform"
        echo
        # Kiểm tra xem phiên bản hiện tại của script cài đặt cho hệ điều hành có khác phiên bản mới nhất hay không?
        if [ "$latest_version_platform" != "$current_version_platform" ]; then
            echo "Phiên bản mới của script cài đặt cho hệ điều hành $type là: $latest_version_platform"
            echo
            # In ra changelog của phiên bản của hệ điều hành.
            print_platform_changelog
            echo
            # Nếu khác thì hỏi người dùng có muốn tải về và cập nhật không?
            read -p "Bạn có muốn tải về và cập nhật phiên bản $latest_version_platform cho $type không? (y/n): " choice
            echo
            # Nếu có thì tải về và cập nhật.
            if [ "$choice" == "y" ]; then
                wget "https://vnscdn.com/platforms/vns-$type.sh" -O "$update_script_dir/vns-$type.sh"
                # Kiểm tra xem tải về và cập nhật thành công hay không?
                if [ "$?" -eq '0' ]; then
                    chmod +x "$update_script_dir/vns-$type.sh"
                    bash "$update_script_dir/vns-$type.sh" "$*"
                    echo
                    echo "Cập nhật phiên bản cho vns-$type.sh hoàn tất."
                    echo
                    exit
                # Nếu không thì báo lỗi và thoát.
                else
                    echo "Lỗi trong quá trình tải về và cập nhật vns-$type.sh."
                    echo
                    exit 1
                fi
            # Nếu không thì bỏ qua.
            else
                echo "Bỏ qua cập nhật vns-$type.sh."
                echo
            fi
        # Nếu không thì báo là phiên bản mới nhất.
        else
            echo "Script vns-$type.sh đã là phiên bản mới nhất."
            echo
        fi
    fi
}

# Hàm kiểm tra và cập nhật cả VNS Script và script cài đặt cho hệ điều hành.
function check_update {
    echo "Kiểm tra cập nhật phiên bản VNS Script..."
    echo
    # Kiểm tra xem VNS Script đã tồn tại chưa? Nếu chưa thì tải về và cài đặt.
    if [ ! -e "$update_script_dir/vns.sh" ]; then
        echo "Tải về VNS Script..."
        echo
        wget "https://vnscdn.com/vns.sh" -O "$update_script_dir/vns.sh"
        if [ "$?" -eq '0' ]; then
            chmod +x "$update_script_dir/vns.sh"
            bash "$update_script_dir/vns.sh" "$*"
            add_update_check_cron
            exit
        else
            echo "Lỗi trong quá trình tải về và cài đặt VNS Script."
            echo
            exit 1
        fi
    # Nếu có rồi thì in ra thông báo đã cài đặt và phiên bản hiện tại.
    else
        # Lấy phiên bản mới nhất của VNS Script từ repo của VNSCDN.
        latest_version=$(curl -s "https://vnscdn.com/latest-version.txt")
        echo "VNS Script đã được cài đặt."
        echo
        echo "Phiên bản hiện tại của VNS Script là: $vns_version"
        echo
        # Kiểm tra xem phiên bản hiện tại của VNS Script có khác phiên bản mới nhất hay không?
        if [ "$latest_version" != "$vns_version" ]; then
            echo "Mhiên bản mới của VNS Script là: $latest_version"
            echo
            # In ra changelog của phiên bản mới của VNS Script.
            print_changelog
            echo
            # Nếu khác thì hỏi người dùng có muốn tải về và cập nhật không?
            read -p "Bạn có muốn tải về và cập nhật phiên bản của VNS Script không? (y/n): " choice
            echo
            # Nếu có thì tải về và cập nhật.
            if [ "$choice" == "y" ]; then
                wget "https://vnscdn.com/vns.sh" -O "$update_script_dir/vns.sh"
                # Kiểm tra xem tải về và cập nhật thành công hay không?
                if [ "$?" -eq '0' ]; then
                    chmod +x "$update_script_dir/vns.sh"
                    bash "$update_script_dir/vns.sh" "$*"
                    echo
                    echo "Cập nhật phiên bản VNS Script hoàn tất. "
                    echo
                    exit
                # Nếu không thì báo lỗi và thoát.
                else
                    echo "Lỗi trong quá trình tải về và cập nhật phiên bản VNS Script."
                    echo
                    exit 1
                fi
            # Nếu không thì bỏ qua.
            else
                echo "Bỏ qua cập nhật phiên bản VNS Script."
                echo
            fi
        # Nếu không thì báo là phiên bản mới nhất.
        else
            echo "VNS Script hiện tại đã là phiên bản mới nhất."
            echo
        fi
    fi

    # Gọi hàm kiểm tra và cập nhật script cài đặt cho hệ điều hành.
    check_and_update_platform_script "$*"
}

# Hàm tạo web cho user với Python và Next.js thông qua proxy NGINX.
function vns_web {
    # Tải script tạo web tương ứng cho hệ điều hành từ repo của VNSCDN về và chạy nó.
    wget "https://vnscdn.com/platforms/vns-web-$type.sh" -O "$update_script_dir/vns-web-$type.sh"
    if [ "$?" -eq '0' ]; then
        chmod +x "$update_script_dir/vns-web-$type.sh"
        bash "$update_script_dir/vns-web-$type.sh" "$*"
        echo
        echo "Cài đặt web cho user hoàn tất."
        echo
        exit
    else
        echo "Lỗi trong quá trình tải về và cài đặt web cho user."
        echo
        exit 1
    fi
}

# Lấy phiên bản Python nếu có hoặc thông báo nếu chưa cài đặt.
python_version=$(python3 -V 2>&1)
if [ $? -eq 0 ]; then
    python_version="Phiên bản Python: $python_version"
else
    python_version="Python chưa được cài đặt."
fi

# Lấy phiên bản Node.js nếu có hoặc thông báo nếu chưa cài đặt.
node_version=$(node -v 2>&1)
if [ $? -eq 0 ]; then
    node_version="Phiên bản Node.js: $node_version"
else
    node_version="Node.js chưa được cài đặt."
fi

# Lấy phiên bản Yarn nếu có hoặc thông báo nếu chưa cài đặt.
yarn_version=$(yarn -v 2>&1)
if [ $? -eq 0 ]; then
    yarn_version="Phiên bản Yarn: $yarn_version"
else
    yarn_version="Yarn chưa được cài đặt."
fi

# Lấy phiên bản PostgreSQL nếu có hoặc thông báo nếu chưa cài đặt.
postgresql_version=$(psql --version 2>&1)
if [ $? -eq 0 ]; then
    postgresql_version="Phiên bản PostgreSQL: $postgresql_version"
else
    postgresql_version="PostgreSQL chưa được cài đặt."
fi

# Lấy phiên bản Nginx nếu có hoặc thông báo nếu chưa cài đặt.
nginx_version=$(nginx -v 2>&1 | grep -o '[0-9.]*')
if [ $? -eq 0 ]; then
    nginx_version="Phiên bản Nginx: $nginx_version"
else
    nginx_version="Nginx chưa được cài đặt."
fi

# Lấy phiên bản Supervisor nếu có hoặc thông báo nếu chưa cài đặt.
supervisor_version=$(supervisord -v 2>&1)
if [ $? -eq 0 ]; then
    supervisor_version="Phiên bản Supervisor: $supervisor_version"
else
    supervisor_version="Supervisor chưa được cài đặt."
fi

# Hiển thị thông tin tác giả khi sử dụng tùy chọn 'info'.
if [ "$1" == "info" ]; then
    cat <<EOF
$0 
#=====================================================================================================
    Tên tập lệnh: VNS Script                                                                               
    Mô tả: Xây dựng máy chủ chạy web tương thích với Python và Next.js cho Linux.                                                                       
    Tác giả: Nguyễn Hồng Thế <nguyenhongthe.net>                                                        
    Ngày: 2023-08-25                                                                                    
    Phiên bản: 1.0.0                                                                                    
    Giấy phép: Giấy phép MIT                                                                            
    Sử dụng: curl -sO https://vnscdn.com/vns.sh && chmod +x vns.sh && bash vns.sh
=====================================================================================================
=====================================================================================================
                                    THÔNG TIN PHIÊN BẢN PACKAGE                                      
=====================================================================================================
=====================================================================================================
    - Phiên bản VNS Script: $vns_version                                                                
    - Phiên bản VNS Script cho Debian: $vns_debian_version
    - Phiên bản VNS Script cho Ubuntu: $vns_ubuntu_version
    - Phiên bản VNS Script cho Amazon Linux: $vns_amazon_version
    - Phiên bản VNS Script cho RHEL: $vns_rhel_version
    - Phiên bản VNS Script cho VNS Website: $vns_website_version                                         
    - Script url: $script_url                                                                           
    - $python_version
    - $node_version
    - $yarn_version
    - $postgresql_version
    - $nginx_version
    - $supervisor_version
=====================================================================================================

EOF
    exit 0
fi

# Kiểm tra nếu tham số là 'web' thì chỉ chạy hàm tạo web.
if [ "$1" == "web" ]; then
    vns_web
    exit
fi

# Kiểm tra nếu tham số là 'changelog' thì chạy hàm in ra changelog của phiên bản mới nhất.
if [ "$1" == "changelog" ]; then
    print_changelog
    echo
    print_platform_changelog
    exit
fi

# Kiểm tra nếu tham số là 'reinstall' thì chạy lại hàm cài đặt VNS Script.
if [ "$1" == "reinstall" ]; then
    update_script_dir=~
    bash "$update_script_dir/vns.sh" "$*"
    exit
fi

# Kiểm tra nếu tham số là 'check-update' thì chạy hàm kiểm tra và cập nhật VNS Script và script cài đặt cho hệ điều hành.
if [ "$1" == "check-update" ]; then
    check_update
    exit
fi

# Kiểm tra số lượng tham số được cung cấp
if [ $# -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    cat <<EOF
Sử dụng: $0 [tùy chọn]

Tùy chọn:
    info            Hiển thị thông tin script.
    -h, --help      Hiển thị hướng dẫn sử dụng.
    check-update    Kiểm tra và cập nhật VNS Script và script cài đặt.
    changelog       In ra changelog của phiên bản mới nhất.
    web             Tạo web cho user với Python và Next.js thông qua proxy NGINX.
    reinstall       Cài đặt lại VNS Script.
EOF
    exit 0
fi

exit
