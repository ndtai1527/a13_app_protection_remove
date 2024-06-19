#!/bin/bash

# Function to find the Java installation path
find_java_home() {
    if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
        echo "JAVA_HOME is already set to: $JAVA_HOME"
        return 0
    fi

    JAVA_PATH=$(dirname $(dirname $(readlink -f $(which java))))
    if [ -n "$JAVA_PATH" ]; then
        echo "Java found at: $JAVA_PATH"
        export JAVA_HOME=$JAVA_PATH
        return 0
    else
        echo "Java not found."
        return 1
    fi
}

# Function to update .bashrc
update_bashrc() {
    if grep -q "export JAVA_HOME" ~/.bashrc; then
        echo "JAVA_HOME already set in .bashrc"
    else
        echo "Adding JAVA_HOME to .bashrc"
        echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
        echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
        echo "JAVA_HOME and PATH updated in .bashrc"
    fi
}

# Main script execution
echo "Setting up JAVA_HOME environment variable..."

find_java_home
if [ $? -eq 0 ]; then
    update_bashrc
    source ~/.bashrc
    echo "JAVA_HOME is set to: $JAVA_HOME"
else
    echo "Failed to set JAVA_HOME. Please install Java and try again."
fi
