/*
Função    : CCADK01
Objetivo  : Manutenção de Contratos e Locais de Contratos.
Parametro : Nil
Retorno   : Nil
Autor     : Alexsander Martins dos Santos
Data      : 10/01/2020
Empresa   : CIEE
*/

#Include "TOTVS.ch"
#Include "FWMVCDEF.ch"
#Include "TOPCONN.ch"

User Function CCADK01()

Local aGetArea    := GetArea()
Local aGetAreaZC0 := ZC0->(GetArea())
Local aGetAreaZC1 := ZC1->(GetArea())
Local aGetAreaSRA := SRA->(GetArea())
Local aGetAreaSA1 := SA1->(GetArea())

Begin Sequence

   CCADK01Browse()

End Sequence

RestArea(aGetAreaSA1)
RestArea(aGetAreaSRA)
RestArea(aGetAreaZC1)
RestArea(aGetAreaZC0)
RestArea(aGetArea)

Return(Nil)


/*
Função    : CCADK01Browse
Objetivo  : Browse dos Contratos
Parametro : Nil
Retorno   : Nil
Autor     : Alexsander Martins dos Santos
Data      : 10/01/2020
Empresa   : CIEE
*/

Static Function CCADK01Browse()

Local aSize

Private cCadastro := "Contratos e Locais de Contratos"
Private aRotina   := {}

Begin Sequence

   /*
   Definição das coordenadas para os objetos visuais.
   */
   aSize    := MsAdvSize()

   aRotina := {{ "Pesquisar",  "AxPesqui",      0, 1 },;		   
			   { "Visualizar", "U_CCADK01View", 0, 2 }}

   mBrowse(6, 1, 22, 75, "ZC0")

End Sequence

Return(Nil)


/*
Função    : CCADK01View
Objetivo  : MSDialog de Visualização dos Contratos e Locais de Contratos.
Parametro : Nil
Retorno   : Nil
Autor     : Alexsander Martins dos Santos
Data      : 10/01/2020
Empresa   : CIEE
*/

User Function CCADK01View()

Local oDlg
Local aSize, aObjects, aInfo, aPosObj

Local bOk      := {|| oDlg:End()}
Local bCancel  := {|| oDlg:End()}

Local aButtons := {{"MAGIC_BMP", {|| CCK01DEP()}, "Dependentes"},;
				   {"MAGIC_BMP", {|| CCK03EVIEW()}, "Conf.Cobrança"},;
				   {"MAGIC_BMP", {|| CCK04EVIEW()}, "Conf.Faturamento"},;
				   {"MAGIC_BMP", {|| CCK01EVIEW()}, "Repres/Contatos"},;
				   {"MAGIC_BMP", {|| CCK01BEN()}, "Beneficiários"}}

//Local aButtons := {{"MAGIC_BMP", {|| CCK01CNI()}, "Conciliação"},;
//                   {"MAGIC_BMP", {|| CCK01DEP()}, "Dependentes"},;
//                   {"MAGIC_BMP", {|| CCK01EVIEW()}, "Repres/Contatos"},;
//                   {"MAGIC_BMP", {|| CCK01BEN()}, "Beneficiários"}}

/*
Declaração dos Objetos Panel
*/
Local oPanelContrato
//Local oPanelLocais
Local oPanelFuncionarios
Local nPos

/*
Declaração dos Objetos MsMGet
*/
Local oMsMGet
Local oMsMGetFields
Local aAcho := {}
Local nxx:= 0
Local aNoSRA:= {}
Local nPAtivo:= 1
/*
Declaração do Folder
*/
Local oTFolder 
Local aTFolder := { 'Locais Contrato', 'Provisionamento Pagar', 'Provisionamento Receber' }
Local aNoFields := {"E2_DATAAGE"}
/*
Declaração das variáveis para Getdados
*/
Private oGDLocais
Private oGDFunc
Private oGDSE2
Private oGDSE1

Private aHeader := {}
Private aCols	:= {}

Private aHLocais := {}
Private aCLocais := {}

Private aHFunc := {}
Private aCFunc := {}

Private aHSE2 := {}
Private aCSE2 := {}

Private aHSE1 := {}
Private aCSE1 := {}

Private bCond     
Private bAction1  
Private bAction2  

//Private aYesFields := {'RA_XATIVO','RA_ADCCONF','RA_ADCTRF ','RA_ADMISSA','RA_ADTPOSE','RA_AFASFGT','RA_ANOCHEG','RA_APELIDO','RA_BAIRRO ','RA_BCDEPSA','RA_BCDPFGT','RA_CARCERT','RA_CARGO  ','RA_CATEFD ','RA_CATEG  ','RA_CATFUNC','RA_CC     ','RA_CDMUCER','RA_CDMURIC','RA_CEP    ','RA_CEPCXPO','RA_CHAPA  ','RA_CIC    ','RA_CLASEST','RA_CLVL   ','RA_CNHORG ','RA_CODACER','RA_CODFUNC','RA_CODIGO ','RA_CODMUN ','RA_CODMUNN','RA_CODPAIS','RA_CODRET ','RA_CODUNIC','RA_COMPLEM','RA_COMPLRG','RA_CPAISOR','RA_CPOSTAL','RA_CRACHA ','RA_CTDEPSA','RA_CTDPFGT','RA_DATCHEG','RA_DATNATU','RA_DDDCELU','RA_DDDFONE','RA_DEMIPAS','RA_DEMISSA','RA_DEPIR  ','RA_DEPSF  ','RA_DEPTO  ','RA_DESEPS ','RA_DEXPRIC','RA_DTCAGED','RA_DTCPEXP','RA_DTEFRET','RA_DTEFRTN','RA_DTEMCNH','RA_DTFIMCT','RA_DTINCON','RA_DTRGEXP','RA_DTVCCNH','RA_DVALPAS','RA_EMAIL  ','RA_EMAIL2 ','RA_EMICERT','RA_EMISPAS','RA_EMISRIC','RA_ENDEREC','RA_ESTADO ','RA_ESTCIVI','RA_EXAMEDI','RA_FICHA  ','RA_FOLCERT','RA_FTINSAL','RA_GRINRAI','RA_HABILIT','RA_HRSDIA ','RA_HRSEMAN','RA_HRSMES ','RA_INSMAX ','RA_ITEM   ','RA_LIVCERT','RA_LOCBNF ','RA_LOGRDSC','RA_LOGRNUM','RA_LOGRTP ','RA_MAE    ','RA_MAT    ','RA_MATCERT','RA_MATMIG ','RA_MOLEST ','RA_MUNICIP','RA_MUNNASC','RA_NACIONA','RA_NACIONC','RA_NASC   ','RA_NATURAL','RA_NJUD14 ','RA_NOME   ','RA_NOMECMP','RA_NRLEIAN','RA_NRPROC ','RA_NSOCIAL','RA_NUMCELU','RA_NUMCP  ','RA_NUMENDE','RA_NUMEPAS','RA_NUMINSC','RA_NUMNATU','RA_NUMRIC ','RA_NUPFCH ','RA_OBSDEFI','RA_OCDTEXP','RA_OCDTVAL','RA_OCEMIS ','RA_OPCAO  ','RA_ORGEMRG','RA_PAI    ','RA_PAISEXT','RA_PERCADT','RA_PERFCH ','RA_PERICUL','RA_PIS    ','RA_PLAPRE ','RA_PORTDEF','RA_POSTO  ','RA_PRCFCH ','RA_PROCES ','RA_REGCIVI','RA_REGISTR','RA_REGRA  ','RA_RESCRAI','RA_RESERVI','RA_RG     ','RA_RGEXP  ','RA_RGORG  ','RA_RGUF   ','RA_RNE    ','RA_RNEDEXP','RA_RNEORG ','RA_ROTFCH ','RA_SECAO  ','RA_SEQTURN','RA_SERCP  ','RA_SERVENT','RA_SERVICO','RA_SINDICA','RA_SITFOLH','RA_TELEFON','RA_TIPOADM','RA_TIPOPGT','RA_TITULOE','RA_TNOTRAB','RA_TPLIVRO','RA_UFCERT ','RA_UFCNH  ','RA_UFCP   ','RA_UFPAS  ','RA_UFRIC  ','RA_USRADM ','RA_VIEMRAI','RA_XATIVO ','RA_XCODMUN','RA_XCODOPE','RA_XDEATIV','RA_XDIGAG ','RA_XDIGCC ','RA_XDIGCON','RA_XDTINTE','RA_XDTNOTF','RA_XFUNCAO','RA_XHRINTE','RA_XID    ','RA_XIDCONF','RA_XIDCONT','RA_XIDLOCT','RA_XOCO   ','RA_XOCOREN','RA_XREJ   ','RA_XREJEIT','RA_ZONASEC'}


Begin Sequence

   /*
   Definicao das coordenadas para os objetos visuais.
   */
   aSize    := MsAdvSize()

   aObjects := {{ 100, 100, .T., .T., .T. },;
				{ 100, 100, .T., .T., .T. },;
				{ 100, 100, .T., .T., .T. }}

   aInfo    := { aSize[1],;
				 aSize[2],;
				 aSize[3],;
				 aSize[4],;
				 5,;
				 5 }

   aPosObj  := MsObjSize(aInfo, aObjects, .T., .F.)

   /*
   Definição da estrutura de campos do MsMGet do Contrato.
   */
   oMsMGetFields := FWFormStruct(1, "ZC0")

   For nPos := 1 To Len(oMsMGetFields:aFields)
	  Aadd(aAcho, AllTrim(oMsMGetFields:aFields[nPos, MODEL_FIELD_IDFIELD]))
   Next

   RegToMemory("ZC0", .F., .F., .F.)

   /*
   Definição do aHeader e aCols para o MsNewGetDados do Locais de Contrato.
   */
   ZC1->(dbSetOrder(1))
   ZC1->(dbSeek(xFilial("ZC1")+ZC0->ZC0_CODIGO))
 
   FillGetDados(2, "ZC1", 1, ZC0->ZC0_FILIAL+ZC0->ZC0_CODIGO, {|| ZC1->ZC1_FILIAL+ZC1->ZC1_CODIGO},,, /*aYesFields*/, /*lOnlyYes*/,, /*bMontCols*/, .F., /*aHeaderAux*/, /*aColsAux*/, , /*bBeforeCols*/,/*bAfterHeader*/, "ZC1")

   aHLocais := ACLONE(aHeader)
   aCLocais := ACLONE(aCols)

   /*
   Definição do aHeader e aCols para títulos a pagar provisório
   */
   
   bCond     := {|| .T.}		      // Se bCond .T. executa bAction1, senao executa bAction2
   bAction1  := {|| vldReg("SE2")}	// Retornar .T. para considerar o registro e .F. para desconsiderar
   bAction2  := {|| .F. }		      // Retornar .T. para considerar o registro e .F. para desconsiderar

   aHeader := {}
   aCols   := {}
   
   SE2->(dbSetOrder(28))
   SE2->(dbSeek(xFilial("SE2")+ZC1->ZC1_CODIGO+ZC1->ZC1_LOCCTR))

   FillGetDados(2, "SE2", 28, xFilial("SE2")+ZC1->ZC1_CODIGO+ZC1->ZC1_LOCCTR, {|| SE2->E2_FILIAL+SE2->E2_XIDCNT+SE2->E2_XIDLOC},{{bCond,bAction1,bAction2}},aNoFields, /*aYesFields*/, /*lOnlyYes*/,, /*bMontCols*/, .F., /*aHeaderAux*/, /*aColsAux*/, , /*bBeforeCols*/,/*bAfterHeader*/, "SE2")

   aHSE2 := ACLONE(aHeader)
   aCSE2 := ACLONE(aCols)

   /*
   Definição do aHeader e aCols para títulos a receber provisório
   */

   bCond     := {|| .T.}		      // Se bCond .T. executa bAction1, senao executa bAction2
   bAction1  := {|| vldReg("SE1")}	// Retornar .T. para considerar o registro e .F. para desconsiderar
   bAction2  := {|| .F. }		      // Retornar .T. para considerar o registro e .F. para desconsiderar

   aHeader := {}
   aCols   := {}
   
   SE1->(dbSetOrder(31))
   SE1->(dbSeek(xFilial("SE1")+ZC1->ZC1_CODIGO+ZC1->ZC1_LOCCTR))

   FillGetDados(2, "SE1", 31, xFilial("SE1")+ZC1->ZC1_CODIGO+ZC1->ZC1_LOCCTR, {|| SE1->E1_FILIAL+SE1->E1_XIDCNT+SE1->E1_XIDLOC},{{bCond,bAction1,bAction2}},, /*aYesFields*/, /*lOnlyYes*/,, /*bMontCols*/, .F., /*aHeaderAux*/, /*aColsAux*/, , /*bBeforeCols*/,/*bAfterHeader*/, "SE1")

   aHSE1 := ACLONE(aHeader)
   aCSE1 := ACLONE(aCols)
   
   /*
   Definição do aHeader e aCols para o MsNewGetDados do Funcionários.
   */
   aHeader := {}
   aCols   := {}
   aNoSRA  := {}	

   SRA->(dbSetOrder(28))
   SRA->(dbSeek(xFilial("SRA")+ZC1->ZC1_CODIGO+ZC1->ZC1_LOCCTR))

   //Aadd(AHeader,{"Status","SRA_OK","@BMP",1,0,".T.",,"C","",,,})
   Aadd(AHeader,{"Status","RA_XATIVO","@BMP",1,0,".T.",,"C","",,,})

   FillGetDados(2, "SRA", 28, xFilial("SRA")+ZC1->ZC1_CODIGO+ZC1->ZC1_LOCCTR, {|| SRA->RA_FILIAL+SRA->RA_XIDCONT+SRA->RA_XIDLOCT},,/*aNoSRA*/, /*aYesFields*/, /*lOnlyYes*/,, /*bMontCols*/, .F., /*aHeaderAux*/, /*aColsAux*/, , /*bBeforeCols*/,/*bAfterHeader*/, "SRA")
   
   
	if SRA->(dbSeek(xFilial("SRA")+ZC1->ZC1_CODIGO+ZC1->ZC1_LOCCTR))
		//Inclusão da Legenda Virtual na GetDados
		nPAtivo:= aScan(aHeader,{|x| AllTrim(x[2])== "RA_XATIVO"})
		For nxx:= 1 To Len (Acols)
			If Acols[nxx,nPAtivo] == "N"
				ACols[nxx,1]:= "BR_VERMELHO"	//Inativo
			Else
				ACols[nxx,1]:= "BR_VERDE"		//Ativo	
			Endif
		Next
	endif
   

   //-----------------------------------------------------------
	
   aHFunc := ACLONE(aHeader)
   aCFunc := ACLONE(aCols)

   Define MsDialog oDlg Title "Contratos" From aSize[7], 0 To aSize[6], aSize[5] Of oMainWnd Pixel STYLE DS_SYSMODAL

   EnchoiceBar(oDlg, bOk, bCancel,, aButtons)

   @ aPosObj[1, 1], aPosObj[1, 2] MSPanel oPanelContrato     Prompt "Contrato"            Colors CLR_BLACK,CLR_WHITE LOWERED RAISED Size aPosObj[1, 3], aPosObj[1, 4] Of oDlg
   oTFolder := TFolder():New( aPosObj[2, 1],aPosObj[2, 2],aTFolder,,oDlg,,,,.T.,,aPosObj[2, 3],aPosObj[2, 4] )
   @ aPosObj[3, 1], aPosObj[3, 2] MSPanel oPanelFuncionarios Prompt "Funcionários"        Colors CLR_BLACK,CLR_WHITE LOWERED RAISED Size aPosObj[3, 3], aPosObj[3, 4] Of oDlg

   /*
   Instância do MsMGet para o Contrato.
   */
   oMsMGet := MsMGet():New("ZC0", ZC0->(Recno()), 2, , , , aAcho, {aPosObj[1, 1]-25, aPosObj[1, 2], aPosObj[1, 4], aPosObj[1, 3]}, , 3, , , , oPanelContrato, .F., .T., .F.,,, .T.)

   /*
   Instância do MsNewGetDados para o Locais do Contrato.
   */
   oGDLocais := MsNewGetDados():New(aPosObj[1, 1]-25, aPosObj[1, 2], aPosObj[1, 4], aPosObj[1, 3], 2,,,,, 0, 99,,,, oTFolder:aDialogs[1], aHLocais, aCLocais)
   aEval(oGDLocais:aHeader,{|x| x[6]:= "" , x[11]:= "" }) //Evitar erro X3_CBOX
   oGDLocais:lInsert := .F.
   oGDLocais:lDelete := .F.
   oGDLocais:lUpdate := .F.
   oGDLocais:Cargo   := "Locais"
   oGDLocais:bChange := {|| LoadChange(Self:Cargo, Self:nAT)}
   oGDLocais:Refresh()

	/*
   Instância do MsNewGetDados para Titulos a pagar provisorio.
   */
   oGDSE2 := MsNewGetDados():New(aPosObj[1, 1]-25, aPosObj[1, 2], aPosObj[1, 4], aPosObj[1, 3], 2,,,,, 0, 99,,,, oTFolder:aDialogs[2], aHSE2, aCSE2)
   aEval(oGDSE2:aHeader,{|x| x[6]:= "" , x[11]:= "" }) //Evitar erro X3_CBOX
   oGDSE2:lInsert := .F.
   oGDSE2:lDelete := .F.
   oGDSE2:lUpdate := .F.
   oGDSE2:Cargo   := "Pagar"
   oGDSE2:Refresh()

	   /*
   Instância do MsNewGetDados para Titulos a receber provisorio.
   */
   oGDSE1 := MsNewGetDados():New(aPosObj[1, 1]-25, aPosObj[1, 2], aPosObj[1, 4], aPosObj[1, 3], 2,,,,, 0, 99,,,, oTFolder:aDialogs[3], aHSE1, aCSE1)
   aEval(oGDSE1:aHeader,{|x| x[6]:= "" , x[11]:= "" }) //Evitar erro X3_CBOX
   oGDSE1:lInsert := .F.
   oGDSE1:lDelete := .F.
   oGDSE1:lUpdate := .F.
   oGDSE1:Cargo   := "Receber"
   oGDSE1:Refresh()

   /*
   Instância do MsNewGetDados para o Funcionários.
   */
   oGDFunc := MsNewGetDados():New(aPosObj[1, 1]-25, aPosObj[1, 2], aPosObj[1, 4], aPosObj[1, 3],2,,,,, 0, 99,,,, oPanelFuncionarios, aHFunc, aCFunc)
   aEval(oGDFunc:aHeader,{|x| x[6]:= "" , x[11]:= "" }) //Evitar erro X3_CBOX
   oGDFunc:lInsert := .F.
   oGDFunc:lDelete := .F.
   oGDFunc:lUpdate := .F.
   oGDFunc:Cargo   := "Funcionarios"
   oGDFunc:Refresh()

   Activate MsDialog oDlg Centered

End Sequence

FreeObj(oGDLocais)
FreeObj(oGDSE2)
FreeObj(oGDSE1)
FreeObj(oGDFunc)

Return(Nil)                           


/*
Função    : LoadChange
Objetivo  : Função chamada na mudança de linha do GetDados.
Parametro : cCargo := Nome do GetDados originário da chamada.
			nLinha := Linha do GetDados após a mudança.
Retorno   : .T.
Autor     : Alexsander Martins dos Santos
Data      : 11/01/2020
Empresa   : CIEE
*/

Static Function LoadChange(cCargo, nLinha)

Local nxx

Local nPos_Contrato
Local nPos_Local

Local cVal_Contrato
Local cVal_Local

//Local nPos

Static lFirstLoad := .T.
Static nOldAT     := 1

Begin Sequence

   If lFirstLoad
	  lFirstLoad := .F.
	  Break
   EndIf

   If nOldAT == nLinha
	  Break
   EndIf

   Do Case

	  Case cCargo == "Locais"

		 nPos_Contrato := GDFieldPos("ZC1_CODIGO", oGDLocais:aHeader)
		 nPos_Local    := GDFieldPos("ZC1_LOCCTR", oGDLocais:aHeader)

		 cVal_Contrato := oGDLocais:aCols[nLinha][nPos_Contrato]
		 cVal_Local    := oGDLocais:aCols[nLinha][nPos_Local]
		 
		 // Atualiza GETDADOS Funcionarios
		 
		 aHeader := {}
		 aCols   := {}
		
		SRA->(dbSetOrder(28))
		SRA->(dbSeek(xFilial("SRA")+cVal_Contrato+cVal_Local))
		
		Aadd(AHeader,{"Status","RA_XATIVO","@BMP",1,0,".T.",,"C","",,,})

		FillGetDados(2, "SRA", 28, xFilial("SRA")+cVal_Contrato+cVal_Local, {|| SRA->RA_FILIAL+SRA->RA_XIDCONT+SRA->RA_XIDLOCT},,, /*aYesFields*/, /*lOnlyYes*/,, /*bMontCols*/, .F., /*aHeaderAux*/, /*aColsAux*/, , /*bBeforeCols*/,/*bAfterHeader*/, "SRA")

      
		if SRA->(dbSeek(xFilial("SRA")+cVal_Contrato+cVal_Local))
			//Inclusão da Legenda Virtual na GetDados
			nPAtivo:= aScan(aHeader,{|x| AllTrim(x[2])== "RA_XATIVO"})
			For nxx:= 1 To Len (Acols)
				If Acols[nxx,nPAtivo] == "N"
					ACols[nxx,1]:= "BR_VERMELHO"	//Inativo
				Else
					ACols[nxx,1]:= "BR_VERDE"		//Ativo	
				Endif
			Next
		endif
      

		oGDFunc:aCols := aCols

//		if SRA->(!Eof())
			oGDFunc:Refresh()
//		endif
		 // Atualiza GETDADOS Titulos a pagar

		 aHeader   := {}
		 aCols     := {}
		 bCond     := {|| .T.}		      // Se bCond .T. executa bAction1, senao executa bAction2
		 bAction1  := {|| vldReg("SE2")}	// Retornar .T. para considerar o registro e .F. para desconsiderar
		 bAction2  := {|| .F. }		      // Retornar .T. para considerar o registro e .F. para desconsiderar

		 FillGetDados(2, "SE2", 28, xFilial("SE2")+cVal_Contrato+cVal_Local, {|| SE2->E2_FILIAL+SE2->E2_XIDCNT+SE2->E2_XIDLOC},{{bCond,bAction1,bAction2}},, /*aYesFields*/, /*lOnlyYes*/,, /*bMontCols*/, .F., /*aHeaderAux*/, /*aColsAux*/, , /*bBeforeCols*/,/*bAfterHeader*/, "SE2")

		 oGDSE2:aCols := aCols
		if SE2->(!Eof())
		 	oGDSE2:Refresh()
		endif

		 // Atualiza GETDADOS Titulos a receber

		 aHeader   := {}
		 aCols     := {}
		 bCond     := {|| .T.}		      // Se bCond .T. executa bAction1, senao executa bAction2
		 bAction1  := {|| vldReg("SE1")}	// Retornar .T. para considerar o registro e .F. para desconsiderar
		 bAction2  := {|| .F. }		      // Retornar .T. para considerar o registro e .F. para desconsiderar

		 FillGetDados(2, "SE1", 31, xFilial("SE1")+cVal_Contrato+cVal_Local, {|| SE1->E1_FILIAL+SE1->E1_XIDCNT+SE1->E1_XIDLOC},{{bCond,bAction1,bAction2}},, /*aYesFields*/, /*lOnlyYes*/,, /*bMontCols*/, .F., /*aHeaderAux*/, /*aColsAux*/, , /*bBeforeCols*/,/*bAfterHeader*/, "SE1")

		 oGDSE1:aCols := aCols
	  If SE1->(!Eof())
		 oGDSE1:Refresh()
	  endif
   End Case

   aHeader := ACLONE(oGDLocais:aHeader)
   aCols   := ACLONE(oGDLocais:aCols)

End Sequence

nOldAT := nLinha

Return(.T.)


/*
Função    : CCADK01Run
Objetivo  : Execução do Carregamento da Tabela ZC0 p/a ZC1.
Parametro : Nil
Retorno   : Nil
Autor     : Alexsander Martins dos Santos
Data      : 10/01/2020
Empresa   : CIEE
*/
//Static Function CCADK01Run()

//Begin Sequence

//   dbSelectArea("ZC0")
//   ZC0->(dbSetOrder(1))

//   dbSelectArea("ZC1")
//   ZC1->(dbSetOrder(1))
   
//   ZC1->(dbGoTop())

//   ProcRegua(ZC1->(RecCount()))

//   While ZC1->(!Eof())

	  /*
	  Unifica o registro de Contrato
	  */
//	  ZC0->(dbSeek(xFilial("ZC0")+ZC1->ZC1_CODIGO))

//	  If ZC0->(Found())
//		 ZC1->(dbSkip())
//		 Loop
//	  EndIf

	  /*
	  Inclusão dos registros na ZC0
	  */      
//	  ZC0->(dbAppend(.F.))

//	  ZC0->ZC0_FILIAL := xFilial("ZC0")    //Filial
//	  ZC0->ZC0_CODIGO := ZC1->ZC1_CODIGO   //Código do Contrato
//	  ZC0->ZC0_TIPCON := ZC1->ZC1_TIPCON   //Tipo do Contrato
//	  ZC0->ZC0_TIPAPR := ZC1->ZC1_TIPAPR   //Tipo do Aprendiz
//	  ZC0->ZC0_PRGAPE := ZC1->ZC1_PRGAPE   //Programa de Aprendizagem
//	  ZC0->ZC0_TIPEMP := ZC1->ZC1_TIPEMP   //Tipo de Empresa
//	  ZC0->ZC0_NOME   := ZC1->ZC1_NOME     //Empresa Razão Social
//	  ZC0->ZC0_NREDUZ := ZC1->ZC1_NREDUZ   //Empresa Nome Reduzido
//	  ZC0->ZC0_NUMDOC := ZC1->ZC1_NUMDOC   //Empresa CNPJ
//	  ZC0->ZC0_STCONV := ZC1->ZC1_STCONV   //Empresa Situação do Convenio
//	  ZC0->ZC0_STEMPR := ZC1->ZC1_STEMPR   //Empresa Situação da Empresa
//	  ZC0->ZC0_FORPGT := ZC1->ZC1_FORPGT   //Empresa Forma de Pagto
//	  ZC0->ZC0_CEPEMP := ZC1->ZC1_CEPEMP   //Empresa CEP
//	  ZC0->ZC0_LOGEMP := ZC1->ZC1_LOGEMP   //Empresa Logradouro
//	  ZC0->ZC0_ENDEMP := ZC1->ZC1_ENDEMP   //Empresa Endereço
//	  ZC0->ZC0_NUMEMP := ZC1->ZC1_NUMEMP   //Empresa Número do Endereço
//	  ZC0->ZC0_COMEMP := ZC1->ZC1_COMEMP   //Empresa Complemento do Endereço
//	  ZC0->ZC0_BAIEMP := ZC1->ZC1_BAIEMP   //Empresa Bairro
//	  ZC0->ZC0_CMUNEM := ZC1->ZC1_CMUNEM   //Empresa Código do Municipio
//	  ZC0->ZC0_CIDEMP := ZC1->ZC1_CIDEMP   //Empresa Cidade
//	  ZC0->ZC0_ESTEMP := ZC1->ZC1_ESTEMP   //Empresa UF

//	  ZC0->(dbCommit())

	  /*
	  Atualização do campo ZC1_CODCTR
	  */      
	  /*
	  ZC1->(RecLock("ZC1", .T.))
	  ZC1->ZC1_CODCTR := ZC1->ZC1_CODIGO   //Código do Contrato
	  ZC1->(MsUnLock())
	  */

//	  ZC1->(dbSkip())

//	  IncProc()

//   End

//End Sequence

//Return(Nil)


/*
Função    : CCK01CNI
Objetivo  : CNI - Conciliação | Créditos Não Identificados
Parametro : Nil
Retorno   : Nil
Autor     : Alexsander Martins dos Santos
Data      : 10/01/2020
Empresa   : CIEE
*/

//Static Function CCK01CNI()

//Local nLinha

//Local nPos_Contrato
//Local nPos_Local

//Local cVal_Contrato
//Local cVal_Local

//Local cSQL

//Begin Sequence

//   If SA1->(FieldPos("A1_XCONTRA")) == 0 .or. SA1->(FieldPos("A1_XLOCCTR")) == 0
//	  MsgAlert("Os campos de Contrato ou Local de Contrato não existem no Cadastro de Cliente", "Atenção")
//	  Break
//   EndIf

   /*
   Obtenção do Contrato e Local do Contrato na linha posicionada no GetDados de Locais.
   */
//   nLinha        := oGDLocais:nAT

//   nPos_Contrato := GDFieldPos("ZC1_CODIGO", oGDLocais:aHeader)
//   nPos_Local    := GDFieldPos("ZC1_LOCCTR", oGDLocais:aHeader)

//   cVal_Contrato := oGDLocais:aCols[nLinha][nPos_Contrato]
//   cVal_Local    := oGDLocais:aCols[nLinha][nPos_Local]

   /*
   Localiza no Cadastro de Cliente
   */
//   cSQL := "SELECT "
//   cSQL += "SA1.R_E_C_N_O_ AS SA1RECNO "

//   cSQL += "FROM "
//   cSQL += RetSQLName("SA1") + " as SA1 "

//   cSQL += "WHERE "
//   cSQL += "SA1.D_E_L_E_T_ <> '*' AND "
//   cSQL += "SA1.A1_FILIAL = '"+xFilial("SA1")+"' AND "
//   cSQL += "SA1.A1_XCONTRA = '"+cVal_Contrato+"' AND "
//   cSQL += "SA1.A1_XLOCCTR = '"+cVal_Local+"'"

//   TCQuery cSQL Alias "RecordSet" New

//   RecordSet->(dbGoTop())

//   If RecordSet->(!Eof())
//	  SA1->(dbGoto(RecordSet->SA1RECNO))
//	  U_C6A87MAT("SA1", RecordSet->SA1RECNO, 3)
//   Else
//	  MsgAlert("Não existe cadastro de cliente vinculado!", "Atenção")
//   EndIf

//   RecordSet->(dbCloseArea())   

//End Sequence

//Return(Nil)


/*
Função    : CCK01DEP
Objetivo  : Dependentes
Parametro : Nil
Retorno   : Nil
Autor     : Alexsander Martins dos Santos
Data      : 10/01/2020
Empresa   : CIEE
*/

Static Function CCK01DEP()

Local nLinha

Local nPos_Matricula
Local cVal_Matricula

Private cCadastro := ""

Begin Sequence

   If Len(oGDFunc:aCols) = 0
	  MsgAlert("Não há funcionários com dependentes vinculados ao Contrato/Local de Contrato.", "Atenção")
	  Break
   EndIf

   nLinha         := oGDFunc:nAT

   nPos_Matricula := GDFieldPos("RA_MAT", oGDFunc:aHeader)
   cVal_Matricula := oGDFunc:aCols[nLinha][nPos_Matricula]

   SRA->(dbSetOrder(1))
   SRA->(dbSeek(xFilial("SRA")+cVal_Matricula))

   FWExecView("Dependentes", "GPEA020", MODEL_OPERATION_VIEW,, {|| .T.}, {|| .T.}, 40,, {|| .T.})

End Sequence

Return(Nil)

/*
Função    : CCK01BEN
Objetivo  : Beneficiários
Parametro : Nil
Retorno   : Nil
Autor     : Alexsander Martins dos Santos
Data      : 10/01/2020
Empresa   : CIEE
*/

Static Function CCK01BEN()

Local nLinha

Local nPos_Matricula
Local cVal_Matricula

Begin Sequence

   If Len(oGDFunc:aCols) = 0
	  MsgAlert("Não há funcionários com beneficiários vinculados ao Contrato/Local de Contrato.", "Atenção")
	  Break
   EndIf

   nLinha         := oGDFunc:nAT

   nPos_Matricula := GDFieldPos("RA_MAT", oGDFunc:aHeader)
   cVal_Matricula := oGDFunc:aCols[nLinha][nPos_Matricula]

   SRA->(dbSetOrder(1))
   SRA->(dbSeek(xFilial("SRA")+cVal_Matricula))

   GPEA280(2)

End Sequence

Return(Nil)

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Rotina de definição do MODEL
@author  	Marcelo Moraes
@since     	07/05/2020
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------

Static Function ModelDef()
local cCpoZC0Vis  := "ZC0_CODIGO|ZC0_NOME|ZC0_NUMDOC"
Local oStruZC0 	:= FWFormStruct(1, "ZC0",{|cCampo| Alltrim(cCampo) $ cCpoZC0Vis})  
Local oModel   	:= MPFormModel():New( 'CCK01MD', /*bPreValidacao*/, /*bPosVld*/, /*bCommit*/ , /*bCancel*/ )

oModel:AddFields("ZC0MASTER", /*cOwner*/, oStruZC0)
oModel:SetPrimaryKey({"ZC0_FILIAL","ZC0_CODIGO"})
oModel:SetDescription("Contratos")

Return oModel

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Rotina de definição do VIEW
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------

Static Function ViewDef()
local cCpoZC0Vis  := "ZC0_CODIGO|ZC0_NOME|ZC0_NUMDOC"
Local oView    	:= FWFormView():New()
Local oStruZC0 	:= FWFormStruct( 2, "ZC0",{|cCampo| Alltrim(cCampo) $ cCpoZC0Vis})  
Local oModel   	:= FWLoadModel("CCADK01")           	

oView:SetModel(oModel)
oView:AddField("VIEW_CAB", oStruZC0, "ZC0MASTER")

oView:AddOtherObject('VIEW_ITEM1',{|Obj| CCK01REP(Obj) },{|| },{||})
oView:AddOtherObject('VIEW_ITEM2',{|Obj| CCK01CON(Obj) },{|| },{||})

oView:CreateHorizontalBox("SUPERIOR", 20)
oView:CreateHorizontalBox("INFERIOR1", 40)
oView:CreateHorizontalBox("INFERIOR2", 40)

oView:SetOwnerView("VIEW_CAB", "SUPERIOR")
oView:SetOwnerView("VIEW_ITEM1", "INFERIOR1")
oView:SetOwnerView("VIEW_ITEM2", "INFERIOR2")

oView:EnableTitleView('VIEW_CAB','Contrato' )
oView:EnableTitleView('VIEW_ITEM1','Representantes' )
oView:EnableTitleView('VIEW_ITEM2','Contatos' )

Return oView

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK01REP
Exibe os representantes
@author  	Marcelo Moraes
@since     	07/05/2020
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
STATIC FUNCTION CCK01REP(Obj)

Local aHeader := {}
Local aCols	  := {}
Local nCnta   := 0
Local oGet    := NIL
Local oJson   := NIL

AADD(aHeader,{"TipoRepre","TIPO","",1,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"Representante","REPRESENTA","",150,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"Cargo","CARGO","",100,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"CPF","CPF","",11,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"TpFone","TIPOFONE","",1,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"DDD","DDD","",2,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"Fone","FONE","",9,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"Ramal","RAMAL","",4,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"Email","EMAIL","",100,0,"",,"C","","V","","",,"V","",,})

if !Empty(ZC0->ZC0_REPR)

   oJson:= JsonObject():new()
   oJson:fromJson(ALLTRIM(ZC0->ZC0_REPR))

   For nCnta:=1 to len(oJson["representantes"])
	  AADD(aCols,{oJson["representantes"][nCnta]:GetJsonText("tipo") ,;
				  oJson["representantes"][nCnta]:GetJsonText("nome") ,;
				  oJson["representantes"][nCnta]:GetJsonText("cargo") ,;
				  oJson["representantes"][nCnta]:GetJsonText("cpf") ,;
				  oJson["representantes"][nCnta]:GetJsonText("tpfone") ,;
				  oJson["representantes"][nCnta]:GetJsonText("ddd") ,;
				  oJson["representantes"][nCnta]:GetJsonText("fone") ,;
				  oJson["representantes"][nCnta]:GetJsonText("ramal") ,;
				  oJson["representantes"][nCnta]:GetJsonText("email") ,;
				  .F.})                   														
   Next		

else

   AADD(aCols,{SPACE(01) ,;
			   SPACE(150) ,;
			   SPACE(100) ,;
			   SPACE(11) ,;
			   SPACE(01) ,;
			   SPACE(02) ,;
			   SPACE(09) ,;
			   SPACE(04) ,;
			   SPACE(100) ,;
			   .F.})                   														
   
endif		

oGet:= MsNewGetDados():New(1,1,1,1,0,"AllwaysTrue","AllwaysTrue",,,,999,"AllwaysTrue()",,,Obj,aHeader,aCols)       	
oGet:oBrowse:Align:= CONTROL_ALIGN_ALLCLIENT

RETURN

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK01REP
Exibe os contatos
@author  	Marcelo Moraes
@since     	07/05/2020
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
STATIC FUNCTION CCK01CON(Obj)

Local aHeader := {}
Local aCols	  := {}
Local nCnta   := 0
Local oGet    := NIL
Local oJson   := NIL

AADD(aHeader,{"Nome","NOME","",150,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"Tipo","TIPO","",1,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"Cargo","CARGO","",150,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"CPF","CPF","",11,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"TpFone","TIPOFONE","",1,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"DDD","DDD","",2,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"Fone","FONE","",9,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"Ramal","RAMAL","",4,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"Email","EMAIL","",100,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"Status","STATUS","",1,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"Segmento","SEGMENTO","",50,0,"",,"C","","V","","",,"V","",,})
AADD(aHeader,{"Departamento","DEPTO","",50,0,"",,"C","","V","","",,"V","",,})

if !Empty(ZC0->ZC0_CONTAT)

   oJson:= JsonObject():new()
   oJson:fromJson(ALLTRIM(ZC0->ZC0_CONTAT))

   For nCnta:=1 to len(oJson["contatos"])
	  AADD(aCols,{oJson["contatos"][nCnta]:GetJsonText("nome") ,;
				  oJson["contatos"][nCnta]:GetJsonText("tipo") ,;
				  oJson["contatos"][nCnta]:GetJsonText("cargo") ,;
				  oJson["contatos"][nCnta]:GetJsonText("cpf") ,;
				  oJson["contatos"][nCnta]:GetJsonText("tpfone") ,;
				  oJson["contatos"][nCnta]:GetJsonText("ddd") ,;
				  oJson["contatos"][nCnta]:GetJsonText("fone") ,;
				  oJson["contatos"][nCnta]:GetJsonText("ramal") ,;
				  oJson["contatos"][nCnta]:GetJsonText("email") ,;
				  oJson["contatos"][nCnta]:GetJsonText("status") ,;
				  oJson["contatos"][nCnta]:GetJsonText("segmento") ,;
				  oJson["contatos"][nCnta]:GetJsonText("departamento") ,;
				  .F.})   
   Next		

else

   AADD(aCols,{SPACE(150) ,;
			   SPACE(01) ,;
			   SPACE(150) ,;
			   SPACE(11) ,;
			   SPACE(01) ,;
			   SPACE(02) ,;
			   SPACE(09) ,;
			   SPACE(04) ,;
			   SPACE(100) ,;
			   SPACE(01) ,;
			   SPACE(50) ,;
			   SPACE(50) ,;
			   .F.})                   														
   
endif		

oGet:= MsNewGetDados():New(1,1,1,1,0,"AllwaysTrue","AllwaysTrue",,,,999,"AllwaysTrue()",,,Obj,aHeader,aCols)       	
oGet:oBrowse:Align:= CONTROL_ALIGN_ALLCLIENT

RETURN

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK01EVIEW
executa a view
@author  	Marcelo Moraes
@since     	07/05/2020
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function CCK01EVIEW()

FWExecView('Representantes','CCADK01',1,,{||.T.})

RETURN

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK03EVIEW
executa a view
@author  	Marcelo Moraes
@since     	07/05/2020
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function CCK03EVIEW()

local aArea    := GetArea()
local aAreaZC3 := ZC3->(GetArea())

dbSelectArea("ZC3")
ZC3->(dbSetOrder(2))
ZC3->(dbSeek(xFilial("ZC3")+ZC0->ZC0_CODIGO))
If ZC3->(Found())
   FWExecView('Cobrança','CCADK03',1,,{||.T.})
else
   alert("Não existe Configuração de Cobrança para este Contrato")
endif

RestArea(aAreaZC3)
RestArea(aArea)

RETURN

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCK03EVIEW
executa a view
@author  	Marcelo Moraes
@since     	07/05/2020
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function CCK04EVIEW()

local aArea    := GetArea()
local aAreaZC4 := ZC4->(GetArea())

dbSelectArea("ZC4")
ZC4->(dbSetOrder(2))
ZC4->(dbSeek(xFilial("ZC4")+ZC0->ZC0_CODIGO))
If ZC4->(Found())
   FWExecView('Cobrança','CCADK04',1,,{||.T.})
else
   alert("Não existe Configuração de Faturamento para este Contrato")
endif

RestArea(aAreaZC4)
RestArea(aArea)

RETURN

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} vldReg
Função usada para validar os registros da função fillgetdados
@author  	Marcelo Moraes
@since     	07/05/2020
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function vldReg(cTabela)

local lRet
local _cCond := IIF(cTabela=="SE2","ALLTRIM(SE2->E2_TIPO)=='PR'","ALLTRIM(SE1->E1_TIPO)=='PR'")

if &_cCond
   lRet := .T.
ELSE
   lRet := .F.
ENDIF

RETURN(lret)
