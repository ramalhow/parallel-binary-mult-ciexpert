	#!/usr/bin/env bash

# Descobre a pasta onde o script está e vai para a raiz do projeto (um nível acima)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$PROJECT_ROOT" || exit 1

# 1. Garante que as pastas de destino existam dentro do seu projeto
mkdir -p db ndm_lib lef tech

# 2. Cria os links simbólicos (usando -sfn para evitar erros se re-executado)

# db
ln -sfn /Tools/PDK/SAED32/EDK_Digital/lib/stdcell_lvt/db_nldm/saed32lvt_ss0p7v125c.db db/
ln -sfn /Tools/PDK/SAED32/EDK_Digital/lib/stdcell_lvt/db_nldm/saed32lvt_tt0p85v25c.db db/

# ndm
ln -sfn /Tools/PDK/SAED32/EDK_Digital/lib/stdcell_lvt/ndm/saed32lvt_base_frame_timing.ndm ndm_lib/

# lef
ln -sfn /Tools/PDK/SAED32/EDK_Digital/lib/stdcell_lvt/lef/saed32nm_lvt_1p9m.lef lef/

# tech files
ln -sfn /Tools/PDK/SAED32/EDK_Digital/tech/tf/saed32nm_1p9m.tf tech/
ln -sfn /Tools/PDK/SAED32/EDK_Digital/tech/map/saed32nm_1p9m_gdsout.map tech/
ln -sfn /Tools/PDK/SAED32/EDK_Digital/tech/starrc/saed32nm_tf_itf_tluplus.map tech/
ln -sfn /Tools/PDK/SAED32/EDK_Digital/tech/starrc/max/saed32nm_1p9m_Cmax.tluplus tech/
ln -sfn /Tools/PDK/SAED32/EDK_Digital/tech/starrc/min/saed32nm_1p9m_Cmin.tluplus tech/
ln -sfn /Tools/PDK/SAED32/EDK_Digital/tech/starrc/nominal/saed32nm_1p9m_nominal.tluplus tech/

# antenna
ln -sfn /Tools/PDK/SAED32/EDK_Digital/tech/ant/saed32nm_ant_1p9m.tcl tech/

echo "Links simbólicos criados com sucesso em $PROJECT_ROOT!"
