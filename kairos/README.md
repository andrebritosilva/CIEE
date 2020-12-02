# **Boas práticas de desenvolvimento Projeto CIEE**

Esse manual de boas práticas tem como objetivo definir convenções e padrões para nomenclatura das personalizações criadas no projeto CIEE.

# **Nomenclatura dos Fontes**

O nome da função dentro de fonte deverá corresponder ao nome do programa obrigatoriamente.

O nome do programa padrão desenvolvido deverá ter oito caracteres de tamanho, seguindo o padrão:

CMMMT999, onde;

**C ->** Fixo; identifica que o fonte pertence ao CIEE.

**MMM ->** três caracteres que identificam o Módulo, sendo:

- ATF = Ativo Fixo
- COM = Compras
- CTB = Contabilidade
- EST = Estoque
- FAT = Faturamento
- FIN = Financeiro
- FIS = Livros Fiscais
- GCT = Gestão de Contratos
- PCO = Planejamento e Controle Orçamentário
- TMK = Field Service
- QDO = Controle de Documentos EAI = EAI (Enterprise Application Integration)
- EAI = EAI (Enterprise Application Integration)

**T ->** um caractere que identifica o Tipo de programa:

- A = Atualização
- C = Consulta
- E = ExecBlock/Gatilho/ Validação de Campo
- R = Relatório

**99 ->** Numeração sequencial de cada módulo.

# **Nomenclatura de SUB-User Function utilizadas dentro dos Fontes.**

O nome da função dentro de fonte deverá corresponder a tabela abaixo:


| Id | Modulo |
| ------ | ------ |
| 1 | ATF |
| 2 | COM |
| 3 | CTB |
| 4 | EST |
| 5 | FAT |
| 6 | FIN |
| 7 | FIS |
| 8 | GCT |
| 9 | PCO |
| A | TMK |
| B | QDO |
| C | EAI |

Exemplo:

```
User Function CEAIA01()
aRotina := { {"Pesquisar", "AxPesqui" , 0, 1},;
           {"Visualizar", "U_CCA01MAT(2)" , 0, 2},;
```

# **Nomenclatura de Funções utilizadas para UPDATES (Compatibilizadores)**

O nome do programa padrão desenvolvido deverá ter oito caracteres de tamanho, seguindo o padrão:

UPGMMM99, onde;

**UP ->** Fixo; identifica que o fonte é um UPDATE.

**G ->** Fixo; identifica que é um Gap.

**MMM ->** três caracteres que identificam o Módulo, sendo:

- ATF = Ativo Fixo
- COM = Compras
- CTB = Contabilidade
- EST = Estoque
- FAT = Faturamento
- FIN = Financeiro
- FIS = Livros Fiscais
- GCT = Gestão de Contratos
- PCO = Planejamento e Controle Orçamentário
- TMK = Field Service
- QDO = Controle de Documentos EAI = EAI (Enterprise Application Integration)
- GPE = Gestão de pessoal
- PON = Ponto Eletrônico
- TRM = Treinamento
- APD = Avaliação Pesquisa Desenvolvimento
- CSA = Cargos e Salarios
- ORG = Arquitetura Organizacional

**99 ->** um sequencial

# **Pontos de Entrada**

O nome do arquivo-fonte que contém o Ponto de Entrada (P.E.) deve corresponder a nomenclatura PE_ mais o nome do próprio P.E.

***Todo o código desenvolvido para o P.E. deve ser tratado através de Funções Especificas “U_” (conforme regra de Nomenclatura de Fontes – acima) deixando assim documentada todas as chamadas de Função dentro do P.E.*****

                    Exemplo:    Ponto de entrada MSD2460
                    Nome do arquivo-fonte: PE_MSD2460.prw

# **Nomenclatura de Campos**     

Campos específicos deverão sempre começar sua nomenclatura com “X”.

                    Exemplo: **B1_XCAMPO**.
                    Campos de tabelas específicas não precisarão seguir esta nomenclatura.

Todos os campos específicos que consultam tabelas padrões devem estar amarrados aos grupos de campo.
Exemplo: B1_XCONTA deve pertencer ao Grupo de Campos denominado “Conta Contábil”

# **Tabelas**

As tabelas específicas devem ser criadas com nome e alias iniciados por **“SZ”**.

# **Parâmetros**

Parâmetros (SX6) específicos devem começar com **“CI_”**.

                    Exemplo: CI_PARAM

# **Índices**

Os índices específicos devem obrigatoriamente possuir nickname.

O nome dos Índices específicos deve seguir a seguinte nomenclatura:

**CI**MMMT99, onde;

**CI ->** Fixo; identifica que o fonte pertence a CIEE.

**MMM ->** três caracteres que identificam o alias da tabela.

**99 ->** Numeração sequencial do índice por tabela.
