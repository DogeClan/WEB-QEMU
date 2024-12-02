# Use the official Debian Bookworm slim base image
FROM debian:bookworm-slim

# Set environment variables for non-interactive installs
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y \
    qemu-system-x86 \
    novnc \
    websockify \
    python3 \
    python3-pip \
    xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Flask and Flask-Cors
RUN pip3 install Flask Flask-Cors

# Create a directory for the Flask app
WORKDIR /app

# Copy the Flask application code into the container
RUN echo "from flask import Flask, request, send_from_directory\n" \
    "import os\n" \
    "import subprocess\n" \
    "import threading\n" \
    "from flask_cors import CORS\n" \
    "\n" \
    "app = Flask(__name__)\n" \
    "CORS(app)  # Enable CORS for all routes\n" \
    "\n" \
    "UPLOAD_FOLDER = '/uploads'\n" \
    "os.makedirs(UPLOAD_FOLDER, exist_ok=True)\n" \
    "\n" \
    "def start_websockify():\n" \
    "    subprocess.Popen(['websockify', '--web', '/usr/share/novnc', '6080', 'localhost:5901'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)\n" \
    "\n" \
    "@app.route('/')\n" \
    "def index():\n" \
    "    return 'Welcome to the QEMU NoVNC uploader!'\n" \
    "\n" \
    "@app.route('/upload', methods=['POST'])\n" \
    "def upload_file():\n" \
    "    if 'file' not in request.files:\n" \
    "        return 'No file part', 400\n" \
    "    file = request.files['file']\n" \
    "    if file.filename == '':\n" \
    "        return 'No selected file', 400\n" \
    "    filepath = os.path.join(UPLOAD_FOLDER, file.filename)\n" \
    "    file.save(filepath)\n" \
    "\n" \
    "    # Start QEMU with the uploaded ISO\n" \
    "    subprocess.Popen([\n" \
    "        'xvfb-run', 'qemu-system-x86_64', \n" \
    "        '-hda', filepath, \n" \
    "        '-nographic', \n" \
    "        '-enable-kvm', \n" \
    "        '-m', '12288',  # 12GB of RAM\n" \
    "        '-vnc', ':0', \n" \
    "        '-spice', 'port=5901,disable-ticketing'\n" \
    "    ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)\n" \
    "\n" \
    "    return f'File uploaded and QEMU started with {file.filename}.', 200\n" \
    "\n" \
    "@app.route('/uploads/<filename>')\n" \
    "def uploaded_file(filename):\n" \
    "    return send_from_directory(UPLOAD_FOLDER, filename)\n" \
    "\n" \
    "if __name__ == '__main__':\n" \
    "    threading.Thread(target=start_websockify).start()\n" \
    "    app.run(host='0.0.0.0', port=5000)\n" > /app/app.py

# Expose the necessary ports for Flask and noVNC
EXPOSE 5000 6080

# Start the Flask application when the container runs
CMD ["python3", "/app/app.py"]
