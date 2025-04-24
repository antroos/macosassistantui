# BrowserAgent - Browser Automation Assistant

A macOS application that combines SwiftUI with Python's browser-use library to create an AI assistant capable of performing tasks in the browser.

## System Components

### Swift Components
- **SwiftUI**: Framework for building the user interface
- **Combine**: For reactive programming and state change handling
- **Foundation**: Core Swift data structures and functions

### Python Components and Dependencies
- **Python**: version 3.12
- **NumPy**: version 1.26.4 (not compatible with 2.x)
- **browser-use**: version 0.1.41 (main browser automation tool)
- **openai**: version 1.76.0 (for OpenAI API integration)
- **langchain-openai**: version 0.3.11 (for LLM integration)
- **pandas**: version 2.2.3 (for data processing)
- **pyarrow**: version 19.0.1 (for pandas interaction)
- **patchright**: (for HTML page patching)

### Environment and Configuration
- **Virtual environment**: `/Users/username/browser_agent_env`
- **Python path**: `/opt/anaconda3/bin/python3`
- **Packages path**: `/Users/username/browser_agent_env/lib/python3.12/site-packages`

## Project Architecture

### Project Structure
- **BrowserAgent/**: Main project directory
  - **Models/**: Data models and logic
    - **ChatViewModel.swift**: Manages chat messages and user interaction
    - **BrowserUseManager.swift**: Manages browser-use agent interaction
    - **Message.swift**: Chat message model
    - **AIModel.swift**: AI model representation
  - **Views/**: Interface components
    - **ContentView.swift**: Main application interface
  - **Python/**: Python code handlers
    - **PythonBridge.swift**: Bridge between Swift and Python
  - **Assets.xcassets/**: Application resources
  - **Preview Content/**: Preview resources

### Key Classes and Functionality
1. **ChatViewModel**: Manages message flow, processes user input
2. **BrowserUseManager**: Interacts with the browser-use Python library, launches the agent
3. **PythonBridge**: Enables Python code execution and environment management
4. **Message**: Represents chat messages with different roles (user, assistant)
5. **AIModel**: Describes AI models and their settings

## Application Workflow
1. User enters a query in the chat interface
2. `ChatViewModel` analyzes the query and determines the required action
3. If the query requires browser actions (contains "open", "find", "go to"):
   - `testRunAgent` in `BrowserUseManager` is called
   - API key status is checked
   - Python code for launching browser-use agent is generated
   - Agent is started through `PythonBridge`
4. Agent performs actions in the browser and returns the result
5. Result is displayed in the interface

## Environment Setup Instructions
1. **Install Python 3.12**:
   ```bash
   brew install python@3.12
   ```

2. **Create a virtual environment**:
   ```bash
   python3.12 -m venv ~/browser_agent_env
   source ~/browser_agent_env/bin/activate
   ```

3. **Install dependencies**:
   ```bash
   pip install numpy==1.26.4
   pip install pandas pyarrow
   pip install browser-use==0.1.41
   pip install openai==1.76.0
   pip install langchain-openai==0.3.11
   pip install patchright
   ```

4. **Configure environment variables**:
   - `PYTHONPATH`: path to site-packages in virtual environment
   - `OPENAI_API_KEY`: OpenAI API key (stored in the app)

## Documentation Enhancement Recommendations
1. **User Interface Overview**:
   - Screenshots with descriptions of each element
   - Usage instructions

2. **Query Examples**:
   - List of example commands that work with the agent
   - Examples of successful queries for opening websites, finding information

3. **API Key Configuration**:
   - Detailed instructions for obtaining an OpenAI API key
   - How to store and edit the key in the program

4. **Expanding Capabilities**:
   - How to add new commands
   - How to integrate additional AI models

5. **Troubleshooting**:
   - Common errors and their solutions
   - Library compatibility issues

## Technical Limitations and Features
1. Uses NumPy version 1.26.4 (not compatible with NumPy 2.x)
2. Requires Chrome or Chromium for browser-use to work
3. Depends on external OpenAI API
4. Asynchronously executes Python code through separate processes
5. Uses reactive programming through Combine for state updates

## API Key Management
The application securely stores API keys in UserDefaults with provider-specific keys. Users can:
- Set a new API key
- Test the API key functionality
- Clear stored API keys

## Known Issues and Solutions
- **NumPy Compatibility**: If you encounter NumPy errors, ensure you're using version 1.26.4, not 2.x
- **Browser Detection**: The agent might fail if Chrome/Chromium isn't installed in standard locations
- **API Rate Limits**: OpenAI API has rate limits which may affect frequent usage 