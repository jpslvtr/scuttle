#!/bin/bash

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null
then
    echo "ImageMagick is not installed. Please install it and try again."
    exit 1
fi

# Set input and output paths
input_image="app/assets/AppIcon-1024.png"
output_dir="app/ios/Runner/Assets.xcassets/AppIcon.appiconset"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Array of desired sizes
sizes=(20 29 40 58 60 76 80 87 120 152 167 180 1024)

# Generate icons
for size in "${sizes[@]}"
do
    output_file="${output_dir}/Icon-App-${size}x${size}.png"
    convert "$input_image" -resize "${size}x${size}!" "$output_file"
    echo "Created $output_file"
done

# Generate special cases
convert "$input_image" -resize "40x40!" "${output_dir}/Icon-App-20x20@2x.png"
convert "$input_image" -resize "60x60!" "${output_dir}/Icon-App-20x20@3x.png"
convert "$input_image" -resize "58x58!" "${output_dir}/Icon-App-29x29@2x.png"
convert "$input_image" -resize "87x87!" "${output_dir}/Icon-App-29x29@3x.png"
convert "$input_image" -resize "80x80!" "${output_dir}/Icon-App-40x40@2x.png"
convert "$input_image" -resize "120x120!" "${output_dir}/Icon-App-40x40@3x.png"
convert "$input_image" -resize "120x120!" "${output_dir}/Icon-App-60x60@2x.png"
convert "$input_image" -resize "180x180!" "${output_dir}/Icon-App-60x60@3x.png"
convert "$input_image" -resize "152x152!" "${output_dir}/Icon-App-76x76@2x.png"
convert "$input_image" -resize "167x167!" "${output_dir}/Icon-App-83.5x83.5@2x.png"

echo "All icons have been generated in the '$output_dir' directory."

# Generate Contents.json file
cat > "${output_dir}/Contents.json" << EOL
{
  "images" : [
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "Icon-App-20x20@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "Icon-App-20x20@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-App-29x29@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-App-29x29@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "Icon-App-40x40@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "Icon-App-40x40@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "Icon-App-60x60@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "Icon-App-60x60@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "20x20",
      "idiom" : "ipad",
      "filename" : "Icon-App-20x20@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "20x20",
      "idiom" : "ipad",
      "filename" : "Icon-App-20x20@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "ipad",
      "filename" : "Icon-App-29x29@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "29x29",
      "idiom" : "ipad",
      "filename" : "Icon-App-29x29@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "ipad",
      "filename" : "Icon-App-40x40@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "40x40",
      "idiom" : "ipad",
      "filename" : "Icon-App-40x40@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "76x76",
      "idiom" : "ipad",
      "filename" : "Icon-App-76x76@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "76x76",
      "idiom" : "ipad",
      "filename" : "Icon-App-76x76@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "83.5x83.5",
      "idiom" : "ipad",
      "filename" : "Icon-App-83.5x83.5@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "1024x1024",
      "idiom" : "ios-marketing",
      "filename" : "Icon-App-1024x1024@1x.png",
      "scale" : "1x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOL

echo "Contents.json file has been generated."