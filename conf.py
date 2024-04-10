project = 'Docker Gitolite'
copyright = '2024, Ding Li'
author = 'Ding Li'

# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration
extensions = []

master_doc = 'README'
exclude_patterns = [
    'Thumbs.db', '.DS_Store', '.git',
    '_build', '.vscode', '.idea', 'venv*',
]

templates_path = ['_templates']

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.h
html_theme = 'alabaster'
html_static_path = ['_static']
