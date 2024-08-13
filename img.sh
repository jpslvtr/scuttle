#!/bin/bash

# Function to resize images with black background
resize_image() {
  local input_file=$1
  local output_file=$2
  local width=$3
  local height=$4

  magick convert "$input_file" -resize "${width}x${height}" -background black -gravity center -extent "${width}x${height}" "$output_file"
}

# Create new directories for each resolution
mkdir -p screenshots/2048x2732-ipad screenshots/1242x2208-iphone55 screenshots/1242x2688-iphone65 screenshots/1290x2796-iphone67

# Process iPhone images
for img in screenshots/iphone/*.png; 
do
  filename=$(basename "$img" .png)
  resize_image "$img" "screenshots/1290x2796-iphone67/${filename}.png" 1290 2796
  resize_image "$img" "screenshots/1242x2688-iphone65/${filename}.png" 1242 2688
  resize_image "$img" "screenshots/1242x2208-iphone55/${filename}.png" 1242 2208
done

# Process iPad images
for img in screenshots/ipad/*.png; 
do
  filename=$(basename "$img" .png)
  resize_image "$img" "screenshots/2048x2732-ipad/${filename}.png" 2048 2732
done

echo "Image resizing complete."