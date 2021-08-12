py -3.9 -m venv --clear .venv
.venv/Scripts/activate
pip install -U pip  # throws [WinError 5], but still works on its own
pip install -r requirements_dev.txt  # packages for development
flit install -s
