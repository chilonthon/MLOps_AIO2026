### 

#### **Step 1: Nuke the Old Dependencies**

In the orignal folder we have these items:

- `lambda_function.py`

- `models/` (folder)

- `processors/` (folder)

- `utils/` (folder)

#### **Step 2: Force a Fresh Linux Download**

Open your terminal inside this  folder. We are going to run the install command again, but this time adding `--no-cache-dir`. This forces pip to ignore your computer's saved files and go directly to the internet to fetch the pure Linux binaries.

PowerShell

```
pip install pandas pydantic -t . --platform manylinux2014_x86_64 --python-version 3.11 --only-binary=:all: --no-cache-dir
```

**Step 3: Zip and Upload in AWS Lambda**

Once the download finishes. Select all the files inside the folder and compress them into `lambda-package.zip`.

After upload sucessfully, we select deploy and wait a little bit.


