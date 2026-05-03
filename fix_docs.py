import sys
import re

def fix_docs(analyze_file, base_dir):
    with open(analyze_file, 'r') as f:
        content = f.read()
    
    # Extract file paths and line numbers
    pattern_dart = re.compile(r'info - (.*?):(\d+):\d+ - Missing documentation')
    pattern_flutter = re.compile(r'info • Missing documentation .*? • (.*?):(\d+):\d+ •')
    
    matches = pattern_dart.findall(content) + pattern_flutter.findall(content)
    
    # Group by file
    files_to_fix = {}
    for filepath, line_num in matches:
        if filepath not in files_to_fix:
            files_to_fix[filepath] = []
        files_to_fix[filepath].append(int(line_num))
        
    for filepath, lines in files_to_fix.items():
        # Sort in descending order to insert from bottom up without affecting previous line numbers
        lines = sorted(list(set(lines)), reverse=True)
        
        full_path = f"{base_dir}/{filepath}"
        try:
            with open(full_path, 'r') as f:
                file_lines = f.readlines()
            
            for line_num in lines:
                idx = line_num - 1 # 0-indexed
                # Determine indentation of the target line
                target_line = file_lines[idx]
                indent = len(target_line) - len(target_line.lstrip())
                indent_str = ' ' * indent
                
                # Check what is being documented to give a slightly better comment if possible
                code_text = target_line.strip()
                doc_text = "/// Documented."
                if code_text.startswith('class '):
                    name = code_text.split('class ')[1].split(' ')[0]
                    doc_text = f"/// {name}."
                elif code_text.startswith('final '):
                    doc_text = "/// Field."
                elif code_text.startswith('const '):
                    doc_text = "/// Constant constructor."
                elif '(' in code_text:
                    doc_text = "/// Method."
                elif code_text.startswith('enum '):
                    name = code_text.split('enum ')[1].split(' ')[0]
                    doc_text = f"/// {name}."
                
                file_lines.insert(idx, f"{indent_str}{doc_text}\n")
                
            with open(full_path, 'w') as f:
                f.writelines(file_lines)
            print(f"Fixed {len(lines)} missing docs in {filepath}")
        except Exception as e:
            print(f"Error processing {filepath}: {e}")

if __name__ == '__main__':
    fix_docs('koi_printer_command/analyze_command.txt', '/Users/max/Workspace/SourceCode/mrkoi/koit_printer/koi_printer_command')
    fix_docs('koi_printer_connection/analyze_connection.txt', '/Users/max/Workspace/SourceCode/mrkoi/koit_printer/koi_printer_connection')
    fix_docs('koi_printer/analyze_printer.txt', '/Users/max/Workspace/SourceCode/mrkoi/koit_printer/koi_printer')
