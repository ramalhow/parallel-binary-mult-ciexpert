#!/bin/bash

# entra na pasta de design
cd ../rtl/

# busca todos os arquivos '.v'
verilog_files=$(ls | grep '\.v$')

echo "Achei os seguintes arquivos .v :"
echo "$verilog_files"

# salva no arquivo filelist.f
for file in $verilog_files
do
  fullname=$(realpath $file)
  echo "salvando o $file no filelist"
  echo "$fullname" >> filelist.f
done

# move o arquivo pra pasta do vcs
mv filelist.f ../tool_data/vcs/filelist.f
