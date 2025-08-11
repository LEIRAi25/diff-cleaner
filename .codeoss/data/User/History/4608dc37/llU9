# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file first to leverage Docker layer caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code and the entrypoint script
COPY diff_cleaner.py .
COPY run.sh .

# Make the entrypoint script executable
RUN chmod +x ./run.sh

# Run the entrypoint script when the container starts
ENTRYPOINT ["./run.sh"]