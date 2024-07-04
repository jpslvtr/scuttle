#!/bin/bash

# Function to resize images with black background
resize_image() {
  local input_file=$1
  local output_file=$2
  local width=$3
  local height=$4

  magick convert "$input_file" -resize "${width}x${height}" -background black -gravity center -extent "${width}x${height}" "$output_file"
}

# Process iPhone images
for img in screenshots/iphone/*.png; 
do
  filename=$(basename "$img" .png)
  resize_image "$img" "screenshots/iphone/${filename}_1290_2796.png" 1290 2796
  resize_image "$img" "screenshots/iphone/${filename}_1242_2688.png" 1242 2688
  resize_image "$img" "screenshots/iphone/${filename}_1242_2208.png" 1242 2208
done

# Process iPad images
for img in screenshots/ipad/*.png; 
do
  filename=$(basename "$img" .png)
  resize_image "$img" "screenshots/ipad/${filename}_2048_2732.png" 2048 2732
done

echo "Image resizing complete."
