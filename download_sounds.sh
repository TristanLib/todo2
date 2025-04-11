#!/bin/bash

# 创建目录
mkdir -p TodoList/TodoList/Resources/Sounds/WhiteNoise

# 下载白噪音文件
# 白噪音 (White Noise)
curl -L "https://freesound.org/data/previews/133/133099_2398403-lq.mp3" -o "TodoList/TodoList/Resources/Sounds/WhiteNoise/none.mp3"
curl -L "https://freesound.org/data/previews/133/133099_2398403-lq.mp3" -o "TodoList/TodoList/Resources/Sounds/WhiteNoise/white_noise.mp3"

# 雨声 (Rain)
curl -L "https://freesound.org/data/previews/243/243627_4355381-lq.mp3" -o "TodoList/TodoList/Resources/Sounds/WhiteNoise/rain.mp3"

# 海浪声 (Ocean)
curl -L "https://freesound.org/data/previews/47/47539_173245-lq.mp3" -o "TodoList/TodoList/Resources/Sounds/WhiteNoise/ocean.mp3"

# 篝火声 (Fire)
curl -L "https://freesound.org/data/previews/160/160653_1561486-lq.mp3" -o "TodoList/TodoList/Resources/Sounds/WhiteNoise/fire.mp3"

# 森林声 (Forest)
curl -L "https://freesound.org/data/previews/197/197784_3633978-lq.mp3" -o "TodoList/TodoList/Resources/Sounds/WhiteNoise/forest.mp3"

# 咖啡厅 (Cafe)
curl -L "https://freesound.org/data/previews/328/328086_5288708-lq.mp3" -o "TodoList/TodoList/Resources/Sounds/WhiteNoise/cafe.mp3"

# 雷声 (Thunder)
curl -L "https://freesound.org/data/previews/102/102806_649468-lq.mp3" -o "TodoList/TodoList/Resources/Sounds/WhiteNoise/thunder.mp3"

# 风声 (Wind)
curl -L "https://freesound.org/data/previews/117/117307_2193190-lq.mp3" -o "TodoList/TodoList/Resources/Sounds/WhiteNoise/wind.mp3"

# 河流声 (River)
curl -L "https://freesound.org/data/previews/44/44255_478468-lq.mp3" -o "TodoList/TodoList/Resources/Sounds/WhiteNoise/river.mp3"

echo "所有白噪音文件下载完成！"
