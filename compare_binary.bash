#!/bin/bash

# Quick File Compare Script
# Usage: ./compare_files.sh file1 file2 [hash_algorithm]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "success")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "error")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "warning")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "info")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Function to format bytes
format_bytes() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes} B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$(( bytes / 1024 )) KB"
    elif [ $bytes -lt 1073741824 ]; then
        echo "$(( bytes / 1048576 )) MB"
    else
        echo "$(( bytes / 1073741824 )) GB"
    fi
}

# Function to compare files
compare_files() {
    local file1=$1
    local file2=$2
    local hash_algo=${3:-sha256}
    
    echo "🔍 Binary File Comparison"
    echo "========================="
    echo
    
    # Check if files exist
    if [ ! -f "$file1" ]; then
        print_status "error" "File not found: $file1"
        return 1
    fi
    
    if [ ! -f "$file2" ]; then
        print_status "error" "File not found: $file2"
        return 1
    fi
    
    # Get file sizes
    size1=$(stat -f%z "$file1" 2>/dev/null || stat -c%s "$file1" 2>/dev/null)
    size2=$(stat -f%z "$file2" 2>/dev/null || stat -c%s "$file2" 2>/dev/null)
    
    echo "📊 File Information:"
    echo "   File 1: $file1 ($(format_bytes $size1))"
    echo "   File 2: $file2 ($(format_bytes $size2))"
    echo
    
    # Quick size check
    if [ "$size1" != "$size2" ]; then
        print_status "error" "Files have different sizes - they cannot be identical"
        echo "   Size 1: $(format_bytes $size1)"
        echo "   Size 2: $(format_bytes $size2)"
        return 1
    fi
    
    print_status "success" "File sizes match ($(format_bytes $size1))"
    echo
    
    # Calculate hashes
    echo "🔐 Hash Comparison ($hash_algo):"
    
    case $hash_algo in
        "md5")
            hash1=$(md5sum "$file1" 2>/dev/null | cut -d' ' -f1 || md5 -q "$file1" 2>/dev/null)
            hash2=$(md5sum "$file2" 2>/dev/null | cut -d' ' -f1 || md5 -q "$file2" 2>/dev/null)
            ;;
        "sha1")
            hash1=$(sha1sum "$file1" 2>/dev/null | cut -d' ' -f1 || shasum -a 1 "$file1" 2>/dev/null | cut -d' ' -f1)
            hash2=$(sha1sum "$file2" 2>/dev/null | cut -d' ' -f1 || shasum -a 1 "$file2" 2>/dev/null | cut -d' ' -f1)
            ;;
        "sha256"|*)
            hash1=$(sha256sum "$file1" 2>/dev/null | cut -d' ' -f1 || shasum -a 256 "$file1" 2>/dev/null | cut -d' ' -f1)
            hash2=$(sha256sum "$file2" 2>/dev/null | cut -d' ' -f1 || shasum -a 256 "$file2" 2>/dev/null | cut -d' ' -f1)
            ;;
        "sha512")
            hash1=$(sha512sum "$file1" 2>/dev/null | cut -d' ' -f1 || shasum -a 512 "$file1" 2>/dev/null | cut -d' ' -f1)
            hash2=$(sha512sum "$file2" 2>/dev/null | cut -d' ' -f1 || shasum -a 512 "$file2" 2>/dev/null | cut -d' ' -f1)
            ;;
    esac
    
    if [ -z "$hash1" ] || [ -z "$hash2" ]; then
        print_status "error" "Failed to calculate hashes"
        return 1
    fi
    
    echo "   File 1: $hash1"
    echo "   File 2: $hash2"
    echo
    
    # Compare hashes
    if [ "$hash1" = "$hash2" ]; then
        print_status "success" "FILES ARE IDENTICAL!"
        echo "   Both files have the same $hash_algo hash"
        echo "   Hash: $hash1"
        return 0
    else
        print_status "error" "FILES ARE DIFFERENT!"
        echo "   The $hash_algo hashes do not match"
        return 1
    fi
}

# Function for batch comparison
batch_compare() {
    local files=("$@")
    local hash_algo="sha256"
    
    echo "🔍 Batch File Comparison"
    echo "========================"
    echo
    
    if [ ${#files[@]} -lt 2 ]; then
        print_status "error" "Need at least 2 files for comparison"
        return 1
    fi
    
    declare -A file_hashes
    declare -A hash_to_files
    
    echo "📊 Calculating hashes for ${#files[@]} files..."
    echo
    
    # Calculate hash for each file
    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            print_status "warning" "Skipping non-existent file: $file"
            continue
        fi
        
        case $hash_algo in
            "sha256"|*)
                hash=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1 || shasum -a 256 "$file" 2>/dev/null | cut -d' ' -f1)
                ;;
        esac
        
        if [ -n "$hash" ]; then
            file_hashes["$file"]=$hash
            if [ -z "${hash_to_files[$hash]}" ]; then
                hash_to_files[$hash]="$file"
            else
                hash_to_files[$hash]="${hash_to_files[$hash]}|$file"
            fi
        fi
    done
    
    # Find duplicates
    duplicates_found=false
    for hash in "${!hash_to_files[@]}"; do
        IFS='|' read -ra files_with_hash <<< "${hash_to_files[$hash]}"
        if [ ${#files_with_hash[@]} -gt 1 ]; then
            if [ "$duplicates_found" = false ]; then
                echo "🔍 DUPLICATE FILES FOUND:"
                echo
                duplicates_found=true
            fi
            
            echo "   Identical files (hash: ${hash:0:16}...):"
            for file in "${files_with_hash[@]}"; do
                size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
                echo "     - $file ($(format_bytes $size))"
            done
            echo
        fi
    done
    
    if [ "$duplicates_found" = false ]; then
        print_status "success" "No duplicate files found - all files are unique"
    fi
    
    echo "📈 Summary:"
    echo "   Total files processed: ${#file_hashes[@]}"
    echo "   Unique files: $(echo "${!hash_to_files[@]}" | wc -w)"
}

# Main script logic
main() {
    case "$1" in
        "--help"|"-h")
            echo "Binary File Comparator"
            echo "======================"
            echo
            echo "Usage:"
            echo "  $0 file1 file2 [hash_algorithm]     # Compare two files"
            echo "  $0 --batch file1 file2 file3 ...    # Compare multiple files"
            echo "  $0 --help                           # Show this help"
            echo
            echo "Hash algorithms: md5, sha1, sha256 (default), sha512"
            echo
            echo "Examples:"
            echo "  $0 proof1.bin proof2.bin"
            echo "  $0 file1.dat file2.dat sha512"
            echo "  $0 --batch *.bin"
            ;;
        "--batch")
            shift
            batch_compare "$@"
            ;;
        *)
            if [ $# -lt 2 ]; then
                print_status "error" "Invalid arguments. Use --help for usage information."
                exit 1
            fi
            compare_files "$@"
            ;;
    esac
}

# Run main function with all arguments
main "$@"