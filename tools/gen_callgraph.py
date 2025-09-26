#!/usr/bin/env python3
"""Generate call graph for Fortran routines in MITgcm."""

import argparse
import re
import os
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple

class FortranCallGraphGenerator:
    def __init__(self, mitgcm_path: str):
        self.mitgcm_path = Path(mitgcm_path)
        self.routines: Dict[str, Dict] = {}
        self.call_graph: Dict[str, Set[str]] = {}
        
    def scan_fortran_files(self) -> None:
        """Scan all Fortran files and extract routine definitions and calls."""
        fortran_files = []
        
        # Find all Fortran files
        for ext in ['*.F', '*.f', '*.f90', '*.F90']:
            fortran_files.extend(self.mitgcm_path.glob(f'**/{ext}'))
        
        print(f"Scanning {len(fortran_files)} Fortran files...")
        
        for file_path in fortran_files:
            try:
                self._process_file(file_path)
            except Exception as e:
                print(f"Warning: Could not process {file_path}: {e}")
        
        print(f"Found {len(self.routines)} routines")
    
    def _process_file(self, file_path: Path) -> None:
        """Process a single Fortran file."""
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read().upper()
        
        # Extract subroutine/function definitions
        subroutine_pattern = r'^\s*SUBROUTINE\s+(\w+)\s*\('
        function_pattern = r'^\s*(?:INTEGER|REAL|DOUBLE\s+PRECISION|LOGICAL|CHARACTER.*?)\s+FUNCTION\s+(\w+)\s*\('
        
        for line in content.split('\n'):
            # Skip comments
            if line.strip().startswith('C') or line.strip().startswith('!'):
                continue
                
            # Find subroutine definitions
            match = re.search(subroutine_pattern, line)
            if match:
                routine_name = match.group(1)
                self.routines[routine_name] = {
                    'file': file_path,
                    'type': 'subroutine',
                    'calls': set()
                }
                self.call_graph[routine_name] = set()
            
            # Find function definitions  
            match = re.search(function_pattern, line)
            if match:
                routine_name = match.group(1)
                self.routines[routine_name] = {
                    'file': file_path,
                    'type': 'function',
                    'calls': set()
                }
                self.call_graph[routine_name] = set()
        
        # Extract calls within each routine
        current_routine = None
        for line in content.split('\n'):
            if line.strip().startswith('C') or line.strip().startswith('!'):
                continue
                
            # Track current routine
            match = re.search(subroutine_pattern, line)
            if match:
                current_routine = match.group(1)
                continue
                
            match = re.search(function_pattern, line) 
            if match:
                current_routine = match.group(1)
                continue
                
            if 'END' in line and current_routine:
                current_routine = None
                continue
                
            # Find CALL statements
            if current_routine and 'CALL' in line:
                call_match = re.search(r'CALL\s+(\w+)\s*\(', line)
                if call_match:
                    called_routine = call_match.group(1)
                    self.routines[current_routine]['calls'].add(called_routine)
                    self.call_graph[current_routine].add(called_routine)
    
    def find_dependencies(self, routine: str) -> Set[str]:
        """Find all routines that a given routine depends on (recursive)."""
        dependencies = set()
        to_visit = [routine]
        visited = set()
        
        while to_visit:
            current = to_visit.pop()
            if current in visited:
                continue
                
            visited.add(current)
            
            if current in self.call_graph:
                for called in self.call_graph[current]:
                    if called not in dependencies:
                        dependencies.add(called)
                        to_visit.append(called)
        
        return dependencies
    
    def generate_mermaid_graph(self, routine: str, max_depth: int = 2) -> str:
        """Generate a Mermaid graph for visualization."""
        lines = ["graph TD"]
        visited = set()
        
        def add_node_and_edges(node: str, depth: int = 0):
            if depth > max_depth or node in visited:
                return
                
            visited.add(node)
            
            if node in self.call_graph:
                for called in self.call_graph[node]:
                    lines.append(f'    {node} --> {called}')
                    add_node_and_edges(called, depth + 1)
        
        add_node_and_edges(routine)
        return '\n'.join(lines)
    
    def analyze_routine(self, routine: str) -> Dict:
        """Analyze a specific routine and its dependencies."""
        if routine not in self.routines:
            return {'error': f'Routine {routine} not found'}
        
        routine_info = self.routines[routine]
        dependencies = self.find_dependencies(routine)
        
        return {
            'routine': routine,
            'file': str(routine_info['file']),
            'type': routine_info['type'],
            'direct_calls': list(routine_info['calls']),
            'all_dependencies': list(dependencies),
            'dependency_count': len(dependencies),
            'mermaid_graph': self.generate_mermaid_graph(routine)
        }
    
    def export_analysis(self, routine: str, output_file: Path) -> None:
        """Export analysis to markdown file."""
        analysis = self.analyze_routine(routine)
        
        if 'error' in analysis:
            print(f"Error: {analysis['error']}")
            return
        
        markdown = f"""# Call Graph Analysis: {routine}

## Routine Information
- **Name**: {analysis['routine']}
- **Type**: {analysis['type']}
- **Source File**: `{analysis['file']}`
- **Total Dependencies**: {analysis['dependency_count']}

## Direct Calls
{chr(10).join(f'- `{call}`' for call in analysis['direct_calls'])}

## All Dependencies
{chr(10).join(f'- `{dep}`' for dep in sorted(analysis['all_dependencies']))}

## Call Graph Visualization

```mermaid
{analysis['mermaid_graph']}
```

## Extraction Complexity
- **Direct dependencies**: {len(analysis['direct_calls'])}
- **Transitive dependencies**: {analysis['dependency_count']}
- **Extraction effort**: {'Low' if analysis['dependency_count'] < 5 else 'Medium' if analysis['dependency_count'] < 15 else 'High'}
"""
        
        with open(output_file, 'w') as f:
            f.write(markdown)
        
        print(f"Analysis exported to {output_file}")

def main():
    parser = argparse.ArgumentParser(description="Generate Fortran call graph for MITgcm routines")
    parser.add_argument("--mitgcm-path", required=True, help="Path to MITgcm source")
    parser.add_argument("--routine", required=True, help="Target routine to analyze")
    parser.add_argument("--output", required=True, help="Output markdown file")
    parser.add_argument("--max-depth", type=int, default=3, help="Maximum graph depth")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.mitgcm_path):
        print(f"Error: MITgcm path {args.mitgcm_path} does not exist")
        return 1
    
    generator = FortranCallGraphGenerator(args.mitgcm_path)
    generator.scan_fortran_files()
    generator.export_analysis(args.routine, Path(args.output))
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
