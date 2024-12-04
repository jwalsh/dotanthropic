#!/usr/bin/env python3

"""
AYGP Status Reporting System
---------------------------
Generates comprehensive status reports and maintains system journal
"""

import json
import logging
import os
import sys
from datetime import datetime
from pathlib import Path

class StatusReporter:
    def __init__(self):
        self.home = os.path.expanduser('~')
        self.base_dir = os.path.join(self.home, '.anthropic')
        self.journal_dir = os.path.join(self.base_dir, 'journal')
        self.log_dir = os.path.join(self.base_dir, 'logs')
        self.config_dir = os.path.join(self.base_dir, 'config')
        
        # Ensure directories exist
        for directory in [self.journal_dir, self.log_dir, self.config_dir]:
            Path(directory).mkdir(parents=True, exist_ok=True)
        
        # Setup logging
        self.setup_logging()
        
    def setup_logging(self):
        """Configure logging for the status reporter"""
        log_file = os.path.join(self.log_dir, 'status_report.log')
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger('StatusReporter')

    def collect_metrics(self):
        """Collect system metrics and agent status"""
        metrics = {
            'timestamp': datetime.now().isoformat(),
            'agents': {},
            'system': {
                'journal_entries': 0,
                'log_size': 0,
                'errors_last_24h': 0
            }
        }
        
        # Count journal entries
        journal_files = Path(self.journal_dir).glob('*.org')
        metrics['system']['journal_entries'] = sum(1 for _ in journal_files)
        
        # Calculate log sizes
        log_files = Path(self.log_dir).glob('*.log')
        metrics['system']['log_size'] = sum(os.path.getsize(f) for f in log_files)
        
        # Count recent errors
        try:
            with open(os.path.join(self.log_dir, 'agents.log')) as f:
                errors = sum(1 for line in f if '[ERROR]' in line)
            metrics['system']['errors_last_24h'] = errors
        except FileNotFoundError:
            self.logger.warning("Agents log file not found")
        
        return metrics

    def generate_report(self):
        """Generate a status report"""
        metrics = self.collect_metrics()
        report_file = os.path.join(self.journal_dir, 
                                 f'status_report_{datetime.now().strftime("%Y%m%d_%H%M%S")}.org')
        
        with open(report_file, 'w') as f:
            f.write("#+TITLE: AYGP System Status Report\n")
            f.write(f"#+DATE: {datetime.now().isoformat()}\n")
            f.write("#+AUTHOR: StatusReporter\n\n")
            
            f.write("* System Status\n")
            for key, value in metrics['system'].items():
                f.write(f"- {key}: {value}\n")
            
            f.write("\n* Agent Status\n")
            try:
                with open(os.path.join(self.config_dir, 'agents.json')) as cfg:
                    agents = json.load(cfg)['agents']
                    for agent, details in agents.items():
                        f.write(f"** {agent}\n")
                        f.write(f"- Model: {details['model']}\n")
                        f.write(f"- Description: {details['description']}\n")
            except FileNotFoundError:
                f.write("No agent configuration found\n")
            
            f.write("\n* Recent Events\n")
            try:
                with open(os.path.join(self.log_dir, 'agents.log')) as log:
                    recent_logs = log.readlines()[-10:]  # Last 10 lines
                    for line in recent_logs:
                        f.write(f"- {line.strip()}\n")
            except FileNotFoundError:
                f.write("No recent events found\n")
        
        self.logger.info(f"Status report generated: {report_file}")
        return report_file

    def journal_entry(self, entry_type, content):
        """Add a journal entry"""
        entry_file = os.path.join(
            self.journal_dir, 
            f'{entry_type}_{datetime.now().strftime("%Y%m%d_%H%M%S")}.org'
        )
        
        with open(entry_file, 'w') as f:
            f.write(f"#+TITLE: {entry_type.title()} Entry\n")
            f.write(f"#+DATE: {datetime.now().isoformat()}\n")
            f.write("#+AUTHOR: AYGP\n\n")
            f.write(content)
        
        self.logger.info(f"Journal entry created: {entry_file}")
        return entry_file

def main():
    reporter = StatusReporter()
    
    # Generate status report
    report_file = reporter.generate_report()
    print(f"Status report generated: {report_file}")
    
    # Add test journal entry
    entry = reporter.journal_entry(
        'system_check',
        """* System Check Results
- All agents responding
- Logs rotated successfully
- Backup completed
"""
    )
    print(f"Journal entry created: {entry}")

if __name__ == '__main__':
    main()