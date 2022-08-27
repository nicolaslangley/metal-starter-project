#!/bin/bash

read -p "Enter new project name: " project_name
sed -i .bak "s/metal-starter-project/$project_name/" ./metal-starter-project.xcodeproj/project.pbxproj
rm ./metal-starter-project.xcodeproj/project.pbxproj.bak
mv ./metal-starter-project.xcodeproj ./$project_name.xcodeproj
sed -i .bak "s/metal-starter-project/$project_name/" ./build.zig
rm ./build.zig.bak

