#Include 'Protheus.ch'
#include 'ParmType.ch'
#include "TbiConn.ch"

/**************************************************************************************************
{Protheus.doc} CFINM01
Geração Arquivo CSV E-SOCIAL
@author Mário A. Cavenaghi
@since 16/07/2020
@version 12.1.25
@type user function
**************************************************************************************************/
User Function CFINM01()

Local lJob    := GetRemoteType() == -1  // Verifica se é job
Local cEmpInt := CEMPANT
Local cFilInt := CFILANT
Local nOpca   := 0

Local aParBox := {}
Local aParRet := {}
Local cDtComp := "AAAAMM"
Local dDtComp := Date() - 30

IF !lJob
	IF MSGYESNO("Geração Arquivo CSV E-SOCIAL ?")
		nOpca:= 1
	ENDIF
ELSE
	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CFINM01] Iniciando processamento via schedule.")
	nOpca:= 1
ENDIF

IF !LockByName("CFINM01",.T.,.T.)
	nOpca:= 0
	IF !lJob
		MSGINFO("Já existe um processamento em execução, aguarde!")
	ELSE
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CFINM01] Já existe um processamento em execução, aguarde!")
	ENDIF
ENDIF

IF nOpca > 0
	
	IF !lJob
		aAdd(aParBox, {1, "Contrato De"         , Space(Len(SRA->RA_XIDCONT)), "", "", "", "", 70, .F.})
		aAdd(aParBox, {1, "Contrato Até"        , Space(Len(SRA->RA_XIDCONT)), "", "", "", "", 70, .F.})
		aAdd(aParBox, {1, "Local do Cliente De" , Space(Len(SRA->RA_XIDLOCT)), "", "", "", "", 70, .F.})
		aAdd(aParBox, {1, "Local do Cliente Até", Space(Len(SRA->RA_XIDLOCT)), "", "", "", "", 70, .F.})
		aAdd(aParBox, {1, "Competência"         , Space(Len(SRD->RD_PERIODO)), "", "", "", "", 70, .F.})

		If ParamBox(aParBox, "Geração Arquivo CSV E-SOCIAL", @aParRet)
			FWMsgRun(,{|| U_CFINM01P(aParRet) },,"Geração Arquivo CSV E-SOCIAL, aguarde...")
		Endif
	ELSE
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CFINM01] Processo Iniciado para "+cEmpInt+"-"+cFilInt)
		cDtComp := Str(Year(dDtComp), 4) + StrZero(Month(dDtComp), 2)
		aParRet := {;
			"               ",;
			"ZZZZZZZZZZZZZZZ",;
			"               ",;
			"ZZZZZZZZZZZZZZZ",;
			cDtComp;
			}
		FWMsgRun(,{|| CFINM01P(aParRet) },,"Geração Arquivo CSV E-SOCIAL, aguarde...")
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CFINM01] Processo Finalizado para "+cEmpInt+"-"+cFilInt)
	ENDIF
	
	UnLockByName("CFINM01",.T.,.T.)
	
ENDIF

Return

/**************************************************************************************************
{Protheus.doc} CFINM01P
Processamento dos dados e Gravação do Arquivo CSV eSocial
@author Mário A. Cavenaghi
@since 16/07/2020
@version 12.1.25
@type user function
**************************************************************************************************/
User Function CFINM01P(aParRet)

Local oJson    := Nil
Local nCampo   := 0
Local nLinha   := 0
Local nHandle  := 0
Local aDados   := {}
Local aLinha   := {}
Local cLinha   := ""
Local cFile    := ""
Local cIdCont  := ""
Local cAlias   := "TAB_CSV"
Local cPeriodo := Right(aParRet[5], 2) + "/" + Left(aParRet[5], 4)
Local cPath    := AllTrim(GetMv("CI_GERESOC", .F., "c:\spool\"))  // Caminho para a geração do arquivo .CSV
Local cCabec   := "COD_CONVENIO;COD_FILIAL;COD_DEPTO;COD_ESTAGIARIO_CIEE;TIPO_CADASTRO;NOME_ESTAGIARIO;NOME_SOCIAL_ESTAGIARIO;DT_NASCIMENTO;COD_IBGE_NASCIMENTO;" + ;
				  "UF_NASCIMENTO;CODPAIS_NASCIMENTO;COD_RACA_COR;RACA_COR;COD_GENERO;GENERO;NATURALIDADE;COD_ESTADO_CIVIL;ESTADO_CIVIL;NOME_MAE;NOME_PAI;TELEFONE_ESTAGIARIO;" + ;
				  "RG;RG_ORGAO_EXP;RG_DT_EXPEDICAO;CPF;PIS_NIS;NUMERO_CTPS;SERIE_CTPS;UF_CTPS;CTPS_ORGAO_EXP;CTPS_DT_EXPEDICAO;NUMERO_RIC;ORGAOE_RIC;DATAEX_RIC;DT_CHEGADO_BR;" + ;
				  "CASADA_BR_SN;TEM_FILHOS_BR_SN;TEM_DEFICIENCIA;TIPO_DEFICIENCIA;TIPO_DEPENDENTE;NOME_DEPENDENTE;DT_NASC_DEPENDENTE;CPF_DEPENDENTE;DEPEND_IRRF_SN;" + ;
				  "DEPEND_SALFAM_SN;DEPEND_CAPFISMEN_TRAB_SN;CODIGO_TRABALHADOR;EMAIL_ESTAGIARIO;CARGA_HORARIA;HORARIO_ESTAGIO;DT_CONTRATO;DT_INICIO_CONTRATO;" + ;
				  "DT_TERMINO_CONTRATO;ESTAGIO_OBRIGATORIO;COD_NIVEL_ESTAGIO;NIVEL_ESTAGIO;COD_CURSO;CURSO;ENDERECO_ESTAGIARIO;BAIRRO_ESTAGIARIO;CEP_ESTAGIARIO;" + ;
				  "CIDADE_ESTAGIARIO;COD_IBGE_ESTAGIARIO;UF_ESTAGIARIO;COD_UF_ESTAGIARIO;COD_AREA_ATUACAO_ESTAG;AREA_ATUACAO_ESTAGIARIO;NUMERO_DA_APOLICE;COD_IE;" + ;
				  "CNPJ_IE;RAZAO_SOCIAL_IE;LOGRADOURO_IE;BAIRRO_IE;CEP_IE;CIDADE_IE;COD_IBGE_IE;UF_IE;UNIDADE_CIEE;CIEE_AUTONOMO;CNPJ_CIEE;RAZAO_SOCIAL_CIEE;LOGRADOURO_CIEE;" + ;
				  "BAIRRO_CIEE;CEP_CIEE;CIDADE_CIEE;COD_IBGE_CIEE;UF_CIEE;COD_SUPERV;CPF_SUPERV;NOME_SUPERV;VALOR_BA_PRIN;VALOR_AT_PRIN;VALOR_ATRBA_PRIN;VALOR_ATRAT_PRIN;" + ;
				  "PENSAO_ALIMENTICIA_PRIN;IMPOSTO_RENDA_PRIN;COMPET_REF_PRIN;VALOR_BA_EVENTO1;VALOR_AT_EVENTO1;VALOR_ATRBA_EVENTO1;VALOR_ATRAT_EVENTO1;" + ;
				  "PENSAO_ALIMENTICIA_EVENTO1;IMPOSTO_RENDA_EVENTO1;COMPET_REF_EVENTO1;VALOR_BA_EVENTO2;VALOR_AT_EVENTO2;VALOR_ATRBA_EVENTO2;VALOR_ATRAT_EVENTO2;" + ;
				  "PENSAO_ALIMENTICIA_EVENTO2;IMPOSTO_RENDA_EVENTO2;COMPET_REF_EVENTO2" + CRLF

Private cTime      := Time()
Private cToken     := U_CINTK12()  // Consulta Token de autenticação
Private cTimeToken := GetMv("CI_SEGTOKE")

// Atualização dos dados complementares SRA (e-Social)
DbSelectArea("SRA")
SRA->(DbSetOrder(01))                                                                                                            

BeginSql Alias cAlias
	SELECT DISTINCT RA_XIDCONT, RA_XIDLOCT, COD_DEPTO = ' ', RA_XID, RA_SITFOLH, RA_NOMECMP, RA_NOME, RA_NASC, RA_CODMUNN, RA_NATURAL, RA_NACIONA, RA_RACACOR,
					RA_DRACACOR = ' ', RA_SEXO, RA_DSEXO = ' ', RA_MUNNASC, RA_ESTCIVI, RA_DESTCIVI = ' ', RA_MAE, RA_PAI, RA_TELEFON, RA_RG, RA_RGEXP, RA_DTRGEXP,
					RA_CIC, RA_PIS, RA_NUMCP, RA_SERCP, RA_UFCP, CTPS_ORGAO_EXP = ' ', RA_DTCPEXP, RA_NUMRIC, RA_EMISRIC, RA_DEXPRIC, RA_DATCHEG, RA_CASADBR,
					RA_FILHOBR, RA_DEFIFIS, RA_PORTDEF, RB_TPDEP, RB_NOME, RB_DTNASC, RB_CIC, RB_TIPIR, RB_TIPSF, DEPEND_CAPFISMEN_TRAB_SN = ' ', RA_CODFUNC,
					RA_EMAIL, RA_HRSDIA, HORARIO_ESTAGIO = ' ', DT_CONTRATO = ' ', RA_ADMISSA, RA_DTFIMCT, ESTAGIO_OBRIGATORIO = ' ', RA_GRINRAI, RA_DESCGIN = ' ',
					COD_CURSO = ' ', CURSO = ' ', RA_ENDEREC, RA_BAIRRO, RA_CEP, RA_MUNICIP, RA_CODMUN, RA_ESTADO, COD_UF_ESTAGIARIO = RA_ESTADO, COD_AREA_ATUACAO_ESTAG = ' ',
					AREA_ATUACAO_ESTAGIARIO = ' ', NUMERO_DA_APOLICE = ' ', COD_IE = ' ', CNPJ_IE = ' ', RAZAO_SOCIAL_IE = ' ', LOGRADOURO_IE = ' ', BAIRRO_IE = ' ',
					CEP_IE = ' ', CIDADE_IE = ' ', COD_IBGE_IE = ' ', UF_IE = ' ', UNIDADE_CIEE = RTRIM(ZC4_UNCIEE) + ' - ' + ZCN_DLOCAL, CIEE_AUTONOMO = ' ', ZCN_CNPJ,
					RAZAO_SOCIAL_CIEE = ' ', ZCN_END, ZCN_BAIRRO, ZCN_CEP, ZCN_CIDADE, COD_IBGE_CIEE = ZCN_CIDADE, ZCN_UF, COD_SUPERV = ' ', CPF_SUPERV = ' ', NOME_SUPERV = ' ',
					RA_MAT  // Esse campo deve último
	FROM %TABLE:SRA% SRA
	INNER JOIN %TABLE:SRD% SRD ON  RA_FILIAL = %xfilial:SRD% AND RD_MAT     = RA_MAT
	 LEFT JOIN %TABLE:SRB% SRB ON  RB_FILIAL = %xfilial:SRB% AND RB_MAT     = RA_MAT
	 LEFT JOIN %TABLE:ZC4% ZC4 ON ZC4_FILIAL = %xfilial:ZC4% AND ZC4_IDCONT = RA_XIDCONT
	 LEFT JOIN %TABLE:ZCN% ZCN ON ZC4_FILIAL = %xfilial:ZCN% AND ZCN_CODIGO = ZC4_UNCIEE
	WHERE SRA.RA_XIDCONT BETWEEN %Exp:aParRet[1]% AND %Exp:aParRet[2]%
	AND SRA.RA_XIDLOCT BETWEEN %Exp:aParRet[3]% AND %Exp:aParRet[4]%
	AND SRD.RD_PERIODO = %Exp:aParRet[5]%
	AND SRA.D_E_L_E_T_ = ' '
	AND SRD.D_E_L_E_T_ = ' '
	ORDER BY RA_XIDCONT, RA_XIDLOCT, COD_DEPTO, RA_XID, RB_NOME
EndSql

//aRet:= GETLastQuery()[2]

(cAlias)->(dbSelectArea((cAlias)))
(cAlias)->(dbGoTop())

While !(cAlias)->(Eof())

	cJson := CFNM01PR((cAlias)->RA_XID,@cToken,@cTime)

	oJson := JsonObject():new()
	oJson:fromJson(cJson)

	if SRA->(DbSeek(xFilial("SRA")+(cAlias)->RA_MAT))

		RecLock("SRA",.F.)
			SRA->RA_PIS     :=  DecodeUTF8(AllTrim(oJson["pis"]))                             // P.I.S.
			SRA->RA_NUMCP   :=  DecodeUTF8(AllTrim(oJson["numeroCtps"]))                      // Cart.Profis.
			SRA->RA_SERCP   :=  DecodeUTF8(AllTrim(oJson["serieCtps"]))                       // Serie Cart.
			SRA->RA_UFCP    :=  DecodeUTF8(AllTrim(oJson["ufCtps"]))                          // UF Cart.Prof
//			SRA->RA_XOREXCP :=  DecodeUTF8(AllTrim(oJson["ctpsOrgaoExp"]))                    // Orgão Exp. Cart.Prof
			SRA->RA_DTCPEXP :=  CtoD(AllTrim(oJson["ctpsDtExpedicao"]))                       // Dt. Emis. CTP
//			SRA->RA_XHOREST :=  DecodeUTF8(AllTrim(oJson["horarioEstagio"]))                  // Horário Estágio
//			SRA->RA_XDTCONT :=  CtoD(AllTrim(oJson["dataContrato"]))                          // Data contrato
//			SRA->RA_XIDCURS :=  oJson["idCurso"]                                              // Id Curso
//			SRA->RA_XDESCUR :=  DecodeUTF8(AllTrim(oJson["descricaoCurso"]))                  // Descr. Curso
//			SRA->RA_XIDARAT :=  oJson["idAreaAtuacaoEstag"]                                   // Id Área Atuação Estágio
//			SRA->RA_XDESARE :=  DecodeUTF8(AllTrim(oJson["descricaoAreaAtuacaoEstagiario"]))  // Descr. Área Atuação Estágio
//			SRA->RA_XNUMAPO :=  DecodeUTF8(AllTrim(oJson["numeroApolice"]))                   // Número Apólice
//			SRA->RA_XIDESCO :=  oJson["idEscola"]                                             // Id Escola
//			SRA->RA_XCNPJES :=  DecodeUTF8(AllTrim(oJson["cnpjEscola"]))                      // CNPJ Escola
//			SRA->RA_XRASOES :=  DecodeUTF8(AllTrim(oJson["razaoSocialEscola"]))               // Razão Social Escola
//			SRA->RA_XLOGRES :=  DecodeUTF8(AllTrim(oJson["logradouroEscola"]))                // Logradouro Escola
//			SRA->RA_XBAIRES :=  DecodeUTF8(AllTrim(oJson["bairroEscola"]))                    // Bairro Escola
//			SRA->RA_XCEPES  :=  DecodeUTF8(AllTrim(oJson["cepEscola"]))                       // CEP Escola
//			SRA->RA_XCIDES  :=  DecodeUTF8(AllTrim(oJson["cidadeEscola"]))                    // Cidade Escola
//			SRA->RA_XIBGEES :=  DecodeUTF8(AllTrim(oJson["codIbgeEscola"]))                   // Código IBGE Escola
//			SRA->RA_XUFES   :=  DecodeUTF8(AllTrim(oJson["ufEscola"]))                        // UF Escola
//			SRA->RA_XIDSUP  :=  oJson["idSupervisor"]                                         // Id Supervisor
//			SRA->RA_XCPFSUP :=  DecodeUTF8(AllTrim(oJson["cpfSupervisor"]))                   // CPF Supervisor
//			SRA->RA_XNOMSUP :=  DecodeUTF8(AllTrim(oJson["nomeSupervisor"]))                  // Nome Supervisor
		SRA->(MsUnlock())

	endif
	
	(cAlias)->(DbSkip())

Enddo

(cAlias)->(DbCloseArea())

BeginSql Alias cAlias
	SELECT DISTINCT RA_XIDCONT, RA_XIDLOCT, COD_DEPTO = ' ', RA_XID, RA_SITFOLH, RA_NOMECMP, RA_NOME, RA_NASC, RA_CODMUNN, RA_NATURAL, RA_NACIONA, RA_RACACOR,
					RA_DRACACOR = ' ', RA_SEXO, RA_DSEXO = ' ', RA_MUNNASC, RA_ESTCIVI, RA_DESTCIVI = ' ', RA_MAE, RA_PAI, RA_TELEFON, RA_RG, RA_RGEXP, RA_DTRGEXP,
					RA_CIC, RA_PIS, RA_NUMCP, RA_SERCP, RA_UFCP, CTPS_ORGAO_EXP = ' ', RA_DTCPEXP, RA_NUMRIC, RA_EMISRIC, RA_DEXPRIC, RA_DATCHEG, RA_CASADBR,
					RA_FILHOBR, RA_DEFIFIS, RA_PORTDEF, RB_TPDEP, RB_NOME, RB_DTNASC, RB_CIC, RB_TIPIR, RB_TIPSF, DEPEND_CAPFISMEN_TRAB_SN = ' ', RA_CODFUNC,
					RA_EMAIL, RA_HRSDIA, HORARIO_ESTAGIO = ' ', DT_CONTRATO = ' ', RA_ADMISSA, RA_DTFIMCT, ESTAGIO_OBRIGATORIO = ' ', RA_GRINRAI, RA_DESCGIN = ' ',
					COD_CURSO = ' ', CURSO = ' ', RA_ENDEREC, RA_BAIRRO, RA_CEP, RA_MUNICIP, RA_CODMUN, RA_ESTADO, COD_UF_ESTAGIARIO = RA_ESTADO, COD_AREA_ATUACAO_ESTAG = ' ',
					AREA_ATUACAO_ESTAGIARIO = ' ', NUMERO_DA_APOLICE = ' ', COD_IE = ' ', CNPJ_IE = ' ', RAZAO_SOCIAL_IE = ' ', LOGRADOURO_IE = ' ', BAIRRO_IE = ' ',
					CEP_IE = ' ', CIDADE_IE = ' ', COD_IBGE_IE = ' ', UF_IE = ' ', UNIDADE_CIEE = RTRIM(ZC4_UNCIEE) + ' - ' + ZCN_DLOCAL, CIEE_AUTONOMO = ' ', ZCN_CNPJ,
					RAZAO_SOCIAL_CIEE = ' ', ZCN_END, ZCN_BAIRRO, ZCN_CEP, ZCN_CIDADE, COD_IBGE_CIEE = ZCN_CIDADE, ZCN_UF, COD_SUPERV = ' ', CPF_SUPERV = ' ', NOME_SUPERV = ' ',
					RA_MAT  // Esse campo deve último
	FROM %TABLE:SRA% SRA
	INNER JOIN %TABLE:SRD% SRD ON  RA_FILIAL = %xfilial:SRD% AND RD_MAT     = RA_MAT
	 LEFT JOIN %TABLE:SRB% SRB ON  RB_FILIAL = %xfilial:SRB% AND RB_MAT     = RA_MAT
	 LEFT JOIN %TABLE:ZC4% ZC4 ON ZC4_FILIAL = %xfilial:ZC4% AND ZC4_IDCONT = RA_XIDCONT
	 LEFT JOIN %TABLE:ZCN% ZCN ON ZC4_FILIAL = %xfilial:ZCN% AND ZCN_CODIGO = ZC4_UNCIEE
	WHERE SRA.RA_XIDCONT BETWEEN %Exp:aParRet[1]% AND %Exp:aParRet[2]%
	AND SRA.RA_XIDLOCT BETWEEN %Exp:aParRet[3]% AND %Exp:aParRet[4]%
	AND SRD.RD_PERIODO = %Exp:aParRet[5]%
	AND SRA.D_E_L_E_T_ = ' '
	AND SRD.D_E_L_E_T_ = ' '
	ORDER BY RA_XIDCONT, RA_XIDLOCT, COD_DEPTO, RA_XID, RB_NOME
EndSql

//aRet:= GETLastQuery()[2]

(cAlias)->(dbSelectArea((cAlias)))
(cAlias)->(dbGoTop())

While !(cAlias)->(Eof())
	
	aLinha := {}
	For nCampo = 1 To (cAlias)->(fCount()) - 1
		aAdd(aLinha, Alltrim((cAlias)->(FieldGet(nCampo))))	 // Se o campo estiver em branco passo para vazio, para reduzir o tamanho do arquivo
	Next

	// Formatação de campos
	aLinha[08] := Iif(Empty(aLinha[08]), '', Right(aLinha[08], 2) + "/" + SubStr(aLinha[08], 5, 2) + "/" + Left(aLinha[08], 4))
	aLinha[13] := Alltrim(X3Combo("RA_RACACOR", aLinha[12]))
	aLinha[15] := Alltrim(X3Combo("RA_SEXO"   , aLinha[14]))
	aLinha[18] := Alltrim(fDesc("SX5", "33" + aLinha[17], "X5_DESCRI"))
	aLinha[24] := Iif(Empty(aLinha[24]), '', Right(aLinha[24], 2) + "/" + SubStr(aLinha[24], 5, 2) + "/" + Left(aLinha[24], 4))
	aLinha[31] := Iif(Empty(aLinha[31]), '', Right(aLinha[31], 2) + "/" + SubStr(aLinha[31], 5, 2) + "/" + Left(aLinha[31], 4))
	aLinha[34] := Iif(Empty(aLinha[34]), '', Right(aLinha[34], 2) + "/" + SubStr(aLinha[34], 5, 2) + "/" + Left(aLinha[34], 4))
	aLinha[35] := Iif(Empty(aLinha[35]), '', Right(aLinha[35], 2) + "/" + SubStr(aLinha[35], 5, 2) + "/" + Left(aLinha[35], 4))
	aLinha[36] := Iif(Empty(aLinha[36]), '', Iif(aLinha[36] == "2", "NAO", "SIM"))
	aLinha[37] := Iif(Empty(aLinha[37]), '', Iif(aLinha[37] == "2", "NAO", "SIM"))
	aLinha[38] := Iif(Empty(aLinha[38]), '', Iif(aLinha[38] == "2", "NAO", "SIM"))
	aLinha[42] := Iif(Empty(aLinha[42]), '', Right(aLinha[42], 2) + "/" + SubStr(aLinha[42], 5, 2) + "/" + Left(aLinha[42], 4))
	aLinha[44] := Iif(Empty(aLinha[44]), '', Iif(aLinha[44] == "4", "NAO", "SIM"))
	aLinha[45] := Iif(Empty(aLinha[45]), '', Iif(aLinha[45] == "3", "NAO", "SIM"))
	aLinha[51] := Iif(Empty(aLinha[51]), '', Right(aLinha[51], 2) + "/" + SubStr(aLinha[51], 5, 2) + "/" + Left(aLinha[51], 4))
	aLinha[52] := Iif(Empty(aLinha[52]), '', Right(aLinha[52], 2) + "/" + SubStr(aLinha[52], 5, 2) + "/" + Left(aLinha[52], 4))
	aLinha[53] := Iif(Empty(aLinha[53]), '', Right(aLinha[53], 2) + "/" + SubStr(aLinha[53], 5, 2) + "/" + Left(aLinha[53], 4))
	aLinha[56] := Alltrim(fDesc("SX5", "26" + aLinha[55], "X5_DESCRI"))

	// RD_FILIAL+RD_MAT+RD_DATARQ+RD_PD+RD_SEMANA+RD_SEQ+RD_CC+RD_PROCES
	// Semana 01
	aAdd(aLinha, Str(Posicione("SRD", 1, xFilial("SRD") + (cAlias)->RA_MAT + aParRet[5] + "00401", "RD_VALOR")))
	aAdd(aLinha, Str(Posicione("SRD", 1, xFilial("SRD") + (cAlias)->RA_MAT + aParRet[5] + "27701", "RD_VALOR")))
	aAdd(aLinha, "0")
	aAdd(aLinha, "0")
	aAdd(aLinha, "0")
	aAdd(aLinha, Str(Posicione("SRD", 1, xFilial("SRD") + (cAlias)->RA_MAT + aParRet[5] + "50901", "RD_VALOR")))
	aAdd(aLinha, Iif(Empty(Val(aLinha[091]) + Val(aLinha[092]) + Val(aLinha[093]) + Val(aLinha[094]) + Val(aLinha[095]) + Val(aLinha[096])), "", cPeriodo))

	// Semana 02
	aAdd(aLinha, Str(Posicione("SRD", 1, xFilial("SRD") + (cAlias)->RA_MAT + aParRet[5] + "00402", "RD_VALOR")))
	aAdd(aLinha, Str(Posicione("SRD", 1, xFilial("SRD") + (cAlias)->RA_MAT + aParRet[5] + "27702", "RD_VALOR")))
	aAdd(aLinha, "0")
	aAdd(aLinha, "0")
	aAdd(aLinha, "0")
	aAdd(aLinha, Str(Posicione("SRD", 1, xFilial("SRD") + (cAlias)->RA_MAT + aParRet[5] + "50902", "RD_VALOR")))
	aAdd(aLinha, Iif(Empty(Val(aLinha[098]) + Val(aLinha[099]) + Val(aLinha[100]) + Val(aLinha[101]) + Val(aLinha[102]) + Val(aLinha[103])), "", cPeriodo))

	// Semana 03
	aAdd(aLinha, Str(Posicione("SRD", 1, xFilial("SRD") + (cAlias)->RA_MAT + aParRet[5] + "00403", "RD_VALOR")))
	aAdd(aLinha, Str(Posicione("SRD", 1, xFilial("SRD") + (cAlias)->RA_MAT + aParRet[5] + "27703", "RD_VALOR")))
	aAdd(aLinha, "0")
	aAdd(aLinha, "0")
	aAdd(aLinha, "0")
	aAdd(aLinha, Str(Posicione("SRD", 1, xFilial("SRD") + (cAlias)->RA_MAT + aParRet[5] + "50903", "RD_VALOR")))
	aAdd(aLinha, Iif(Empty(Val(aLinha[105]) + Val(aLinha[106]) + Val(aLinha[107]) + Val(aLinha[108]) + Val(aLinha[109]) + Val(aLinha[110])), "", cPeriodo))

	For nLinha := 91 To Len(aLinha)
		aLinha[nLinha] := StrTran(Alltrim(aLinha[nLinha]), ".", ",")
	Next

	aAdd(aDados, aLinha)

	(cAlias)->(DbSkip())

Enddo

(cAlias)->(DbCloseArea())

For nLinha = 1 To Len(aDados)
	If cIdCont <> aDados[nLinha, 1]
		cIdCont := aDados[nLinha, 1]
		cFile := cPath + aDados[nLinha, 1] + "_esocial_" + StrTran(cPeriodo, "/", "") + "_" + CEMPANT + CFILANT + ".csv"  //  RA_XIDCONT + esocial + RD_PERIODO + Empresa + Filial
		If nHandle > 0
			FClose(nHandle)
		Endif
		nHandle := fCreate(cFile)

		If nHandle = -1
			cLinha := "Erro ao criar arquivo: " + cFile + " - " + Alltrim(Str(Ferror()))

			If IsBlind()  // JOB
				ConOut("INFO: Called from " + FunName() + ", " + cLinha)
			Else          // TELA
				MsgInfo(cLinha, "ATENÇÃO")
			Endif
		Else
			fWrite(nHandle, cCabec)
		Endif
	Endif

	If nHandle > 0  // Assim pula as linhas referentes ao contrato do arquivo que deu erro
		cLinha := ""
		For nCampo = 1 To Len(aDados[1])
			cLinha += aDados[nLinha, nCampo] + ";"
		Next
		cLinha := Left(cLinha, Len(cLinha) - 1) + CRLF  // Tira o Último ";"
		fWrite(nHandle, cLinha)
	Endif
Next
If nHandle > 0
	FClose(nHandle)
Endif
If !IsBlind()  // TELA
	MsgInfo("Arquivos salvos em " + cPath, "ATENÇÃO")
Endif

Return

/*/{Protheus.doc} CFNM01PR
Método para atualizar os dados complementares SRA (e-Social)
@author danilo.grodzicki
@since 20/11/2020
@version undefined
@type function
/*/
Static function CFNM01PR(cCodTcetca,cToken,cTime)

Local cJson   := " "
Local oRest   := Nil
Local aHeader := {}

if ElapTime(cTime, Time()) >= cTimeToken
	cTime  := Time()
	cToken := U_CINTK12()  // Consulta Token de autenticação
endif

oRest := FWRest():New("https://api.ppd.ciee.org.br")

aAdd(aHeader,'Content-Type: multipart/form-data')
aAdd(aHeader,'Authorization: Bearer ' + cToken )

oRest:SetPath("/vagas/contratos-estudante-empresa/" + cCodTcetca + "/esocial-complementar")

If oRest:Get(aHeader)
	cJson := oRest:GetResult()
Endif

Return(cJson)

/*/{Protheus.doc} Scheddef
Define parametros do processamento via schedule
@author danilo.grodzicki
@since 20/11/2020
@version undefined
@type function
/*/
Static Function Scheddef()

Local aParam := {"P","CFINM01","",{},""}

Return aParam