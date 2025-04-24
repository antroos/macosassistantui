import Foundation

class PythonBridge {
    static let shared = PythonBridge()
    
    // Шлях до Python у віртуальному середовищі - використовуємо повний шлях
    private let pythonPath: String = "/opt/anaconda3/bin/python3"
    // Шлях до віртуального середовища
    private let venvPath: String = "/Users/ivanpasichnyk/browser_agent_env"
    // Шлях до browser-use та інших пакетів
    private let packagesPath: String = "/Users/ivanpasichnyk/browser_agent_env/lib/python3.12/site-packages"
    
    private init() {
        setupPythonEnvironment()
    }
    
    private func setupPythonEnvironment() {
        // Встановлення змінних середовища для Python
        setenv("PYTHONPATH", packagesPath, 1)
    }
    
    func installBrowserUse() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: pythonPath)
        task.arguments = ["-m", "pip", "install", "browser-use"]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            print("Error installing browser-use: \(error)")
            return false
        }
    }
    
    func checkPatchrightInstallation() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: pythonPath)
        task.arguments = ["-c", "import patchright; print('Installed')"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), output.contains("Installed") {
                return true
            }
            return false
        } catch {
            print("Error checking Patchright: \(error)")
            return false
        }
    }
    
    func installPatchright() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: pythonPath)
        task.arguments = ["-m", "pip", "install", "patchright"]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            print("Error installing Patchright: \(error)")
            return false
        }
    }
    
    // Функція, яка перевіряє, чи всі необхідні залежності встановлені
    func checkDependencies() -> [String: Bool] {
        return [
            "browser_use": checkBrowserUseInstallation(),
            "patchright": checkPatchrightInstallation()
        ]
    }
    
    private func checkBrowserUseInstallation() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: pythonPath)
        task.arguments = ["-c", "import browser_use; print('Installed')"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), output.contains("Installed") {
                return true
            }
            return false
        } catch {
            print("Error checking browser-use: \(error)")
            return false
        }
    }
    
    // Функція для запуску Python коду
    func runPythonCode(code: String) -> String {
        let task = Process()
        
        // Використовуємо прямий шлях до Python
        task.executableURL = URL(fileURLWithPath: pythonPath)
        
        // Створюємо тимчасовий файл для Python коду
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("browser_agent_script.py")
        
        do {
            try code.write(to: tempFile, atomically: true, encoding: .utf8)
            
            task.arguments = [tempFile.path]
            
            // Встановлюємо змінні середовища для процесу
            var environment = ProcessInfo.processInfo.environment
            environment["PYTHONPATH"] = packagesPath
            environment["VIRTUAL_ENV"] = venvPath
            
            task.environment = environment
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            task.standardOutput = outputPipe
            task.standardError = errorPipe
            
            try task.run()
            task.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""
            
            // Видаляємо тимчасовий файл
            try FileManager.default.removeItem(at: tempFile)
            
            if !error.isEmpty {
                print("Python error: \(error)")
                return "Помилка: \(error)"
            }
            
            return output
        } catch {
            print("Error running Python code: \(error)")
            return "Помилка виконання коду: \(error.localizedDescription)"
        }
    }
} 