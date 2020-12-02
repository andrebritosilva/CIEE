#Include 'Protheus.ch'
#Include 'Topconn.ch'
#include "ap5mail.ch"
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCTBS01
Rotina de atualização das amarrações contábeis
@author  	Carlos Henrique
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CCTBS01(lInJob)
Local lRet		:= .T.
DEFAULT lInJob	:= .F.

IF lInJob
	STARTJOB("U_CCTBJOB",Getenvserver(),.F.,{CEMPANT,CFILANT})
ELSE
	IF (lRet:= MSGYESNO("Confirma a atualização das amarrações ?")) 
		MsgRun("Gerando tabela de amarrações, aguarde!!",,{|| lRet:= C34S01EX() })
	Endif
ENDIF

RETURN  lRet 

/*/{Protheus.doc} CCTBJOB
Rotina de execução em job
@author carlos.henrique
@since 30/01/2018
@version undefined

@type function
/*/
User Function CCTBJOB(aParam)
local cEmp	:= ""
local cFil	:= ""

If aParam == Nil
	U_uCONOUT("Parametro invalido => CCTBS01")
ELSE	
	cEmp := alltrim(aParam[1])
	cFil := alltrim(aParam[2])
	
	RpcSetType(3)
	IF RPCSetEnv(cEmp,cFil)                                                                                                              
		U_uCONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CCTBS01] Processo Iniciado para "+cEmp+"-"+cFil)
		C34S01EX(.T.) 
		U_uCONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CCTBS01] Processo Finalizado para "+cEmp+"-"+cFil)	
		RpcClearEnv()
	ENDIF	
EndIf

RETURN
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} C34S01EX
Rotina de atualização das amarrações contábeis
@author  	Carlos Henrique
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
STATIC FUNCTION C34S01EX(lJob)
Local cTab	:= "TMPCTA"
Local lRet	:= .T.
Local cSetor:= ""
Local cRegra:= ""
Local cItem	:= ""
Local cQry	:= ""
Local nItem	:= 0
Local cMsg	:= ""
Default lJob:= .F.

cQry:= " DROP TABLE "+cTab

IF TCSQLEXEC(cQry) < 0
	U_uCONOUT("Erro ao excluir a tebela temporaria de amarrações: "+cTab)
endif

cQry:= " SELECT CTA_FILIAL"+CRLF 
cQry+= " 	  ,CTA_REGRA"+CRLF
cQry+= " 	  ,CTA_DESC"+CRLF
cQry+= " 	  ,CTA_NIVEL"+CRLF
cQry+= " 	  ,ROW_NUMBER() OVER(PARTITION BY CTA_REGRA ORDER BY CTA_ITEM ASC) AS CTA_ITREGR"+CRLF
cQry+= " 	  ,CTA_CONTA"+CRLF
cQry+= " 	  ,CTA_CUSTO"+CRLF
cQry+= " 	  ,CTA_ITEM"+CRLF
cQry+= " 	  ,CTA_CLVL"+CRLF
cQry+= " 	  ,CTA_ENTI05"+CRLF
cQry+= " 	  ,ROW_NUMBER() OVER(ORDER BY CTA_FILIAL ASC) AS R_E_C_N_O_"+CRLF
cQry+= " INTO "+cTab+" FROM ("+CRLF
cQry+= " 	SELECT '"+XFILIAL("CTA")+"' AS CTA_FILIAL"+CRLF
cQry+= " 			,LEFT(CT1_CONTA,1)+REPLICATE('0',5-LEN(CTD_ITEM)) + CTD_ITEM AS CTA_REGRA"+CRLF
cQry+= " 			,'REGRA SETOR '+CTD_ITEM AS CTA_DESC"+CRLF
cQry+= " 			,'1' AS CTA_NIVEL"+CRLF
cQry+= " 			,CT1_CONTA AS CTA_CONTA"+CRLF
cQry+= " 			,CTT_CUSTO AS CTA_CUSTO"+CRLF
cQry+= " 			,CTD_ITEM AS CTA_ITEM"+CRLF
cQry+= " 			,CTH_CLVL AS CTA_CLVL"+CRLF
cQry+= " 			,CV0_CODIGO AS CTA_ENTI05"+CRLF
cQry+= " 	   FROM "+RETSQLNAME("CTD")+" CTD WITH (NOLOCK)"+CRLF
cQry+= " 	   INNER JOIN "+RETSQLNAME("CTT")+" CTT WITH (NOLOCK) ON CTT_CUSTO=CTD_XCCPDR"+CRLF
cQry+= " 	   AND CTT.D_E_L_E_T_=''"+CRLF
cQry+= " 	   INNER JOIN "+RETSQLNAME("CTH")+" CTH WITH (NOLOCK) ON CTH_CLVL=CTD_XATPDR"+CRLF
cQry+= " 	   AND CTH.D_E_L_E_T_=''"+CRLF
cQry+= " 	   INNER JOIN "+RETSQLNAME("CV0")+" CV0 WITH (NOLOCK) ON CV0_PLANO='05'"+CRLF
cQry+= " 	   AND CV0_CODIGO=CTT_XUNIPD"+CRLF
cQry+= " 	   AND CV0.D_E_L_E_T_=''"+CRLF
cQry+= " 	   INNER JOIN "+RETSQLNAME("CT1")+" CT1 WITH (NOLOCK) ON LEFT(CT1_CONTA,1)='1'"+CRLF
cQry+= " 	   AND CT1_XATBLQ!=CTD_XATPDR"+CRLF
cQry+= " 	   AND (CT1_XATPDR=CTD_XATPDR"+CRLF
cQry+= " 			OR CT1_XATPDR='')"+CRLF
cQry+= " 	   AND CT1_CLASSE='2'"+CRLF
cQry+= " 	   AND CT1_BLOQ='2'"+CRLF
cQry+= " 	   AND CT1.D_E_L_E_T_=''"+CRLF
cQry+= " 	   WHERE CTD_CLASSE='2'"+CRLF
cQry+= " 		 AND CTD_BLOQ='2'"+CRLF
cQry+= " 		 AND CTD.D_E_L_E_T_=''"+CRLF
cQry+= " 	UNION ALL"+CRLF
cQry+= " 	SELECT '"+XFILIAL("CTA")+"' AS CTA_FILIAL"+CRLF
cQry+= " 			,LEFT(CT1_CONTA,1)+REPLICATE('0',5-LEN(CTD_ITEM)) + CTD_ITEM AS CTA_REGRA"+CRLF
cQry+= " 			,'REGRA SETOR '+CTD_ITEM AS CTA_DESC"+CRLF
cQry+= " 			,'1' AS CTA_NIVEL"+CRLF
cQry+= " 			,CT1_CONTA AS CTA_CONTA"+CRLF
cQry+= " 			,CTT_CUSTO AS CTA_CUSTO"+CRLF
cQry+= " 			,CTD_ITEM AS CTA_ITEM"+CRLF
cQry+= " 			,CTH_CLVL AS CTA_CLVL"+CRLF
cQry+= " 			,CV0_CODIGO AS CTA_ENTI05"+CRLF
cQry+= " 	   FROM "+RETSQLNAME("CTD")+" CTD WITH (NOLOCK)"+CRLF
cQry+= " 	   INNER JOIN "+RETSQLNAME("CTT")+" CTT WITH (NOLOCK) ON CTT_CUSTO=CTD_XCCPDR"+CRLF
cQry+= " 	   AND CTT.D_E_L_E_T_=''"+CRLF
cQry+= " 	   INNER JOIN "+RETSQLNAME("CTH")+" CTH WITH (NOLOCK) ON CTH_CLVL=CTD_XATPDR"+CRLF
cQry+= " 	   AND CTH.D_E_L_E_T_=''"+CRLF
cQry+= " 	   INNER JOIN "+RETSQLNAME("CV0")+" CV0 WITH (NOLOCK) ON CV0_PLANO='05'"+CRLF
cQry+= " 	   AND CV0_CODIGO=CTT_XUNIPD"+CRLF
cQry+= " 	   AND CV0.D_E_L_E_T_=''"+CRLF
cQry+= " 	   INNER JOIN "+RETSQLNAME("CT1")+" CT1 WITH (NOLOCK) ON LEFT(CT1_CONTA,1) IN ('3','4')"+CRLF
cQry+= " 	   AND LEFT(CT1_CONTA,1)= CASE"+CRLF
cQry+= " 								  WHEN CTH_CLVL= '9' THEN '4'"+CRLF
cQry+= " 								  ELSE '3'"+CRLF
cQry+= " 							  END"+CRLF
cQry+= " 	   AND CT1_XATBLQ!=CTD_XATPDR"+CRLF
cQry+= " 	   AND (CT1_XATPDR=CTD_XATPDR"+CRLF
cQry+= " 			OR CT1_XATPDR='')"+CRLF
cQry+= " 	   AND CT1_CLASSE='2'"+CRLF
cQry+= " 	   AND CT1_BLOQ='2'"+CRLF
cQry+= " 	   AND CT1.D_E_L_E_T_=''"+CRLF
cQry+= " 	   WHERE CTD_CLASSE='2'"+CRLF
cQry+= " 		 AND CTD_BLOQ='2'"+CRLF
cQry+= " 		 AND CTD.D_E_L_E_T_=''"+CRLF
cQry+= " 	UNION ALL"+CRLF
cQry+= " 	SELECT '"+XFILIAL("CTA")+"' AS CTA_FILIAL"+CRLF
cQry+= " 			,LEFT(CT1_CONTA,1)+REPLICATE('0',5-LEN(CTD_ITEM)) + CTD_ITEM AS CTA_REGRA"+CRLF
cQry+= " 			,'REGRA SETOR '+CTD_ITEM AS CTA_DESC"+CRLF
cQry+= " 			,'1' AS CTA_NIVEL"+CRLF
cQry+= " 			,CT1_CONTA AS CTA_CONTA"+CRLF
cQry+= " 			,CTT_CUSTO AS CTA_CUSTO"+CRLF
cQry+= " 			,CTD_ITEM AS CTA_ITEM"+CRLF
cQry+= " 			,CTH_CLVL AS CTA_CLVL"+CRLF
cQry+= " 			,CV0_CODIGO AS CTA_ENTI05"+CRLF
cQry+= " 	   FROM "+RETSQLNAME("CTD")+" CTD"+CRLF
cQry+= " 	   INNER JOIN "+RETSQLNAME("CTT")+" CTT ON CTT_CUSTO=CTD_XCCPDR"+CRLF
cQry+= " 	   AND CTT.D_E_L_E_T_=''"+CRLF
cQry+= " 	   INNER JOIN "+RETSQLNAME("CTH")+" CTH ON CTH_CLVL=CTD_XATPDR"+CRLF
cQry+= " 	   AND CTH.D_E_L_E_T_=''"+CRLF
cQry+= " 	   INNER JOIN "+RETSQLNAME("CV0")+" CV0 ON CV0_PLANO='05'"+CRLF
cQry+= " 	   AND CV0_CODIGO=CTT_XUNIPD"+CRLF
cQry+= " 	   AND CV0.D_E_L_E_T_=''"+CRLF
cQry+= " 	   INNER JOIN "+RETSQLNAME("CT1")+" CT1 ON LEFT(CT1_CONTA,1) IN ('5')"+CRLF
cQry+= " 	   AND CT1_XATBLQ!=CTD_XATPDR"+CRLF
cQry+= " 	   AND (CT1_XATPDR=CTD_XATPDR"+CRLF
cQry+= " 			OR CT1_XATPDR='')"+CRLF
cQry+= " 	   AND CT1_CLASSE='2'"+CRLF
cQry+= " 	   AND CT1_BLOQ='2'"+CRLF
cQry+= " 	   AND CT1.D_E_L_E_T_=''"+CRLF
cQry+= " 	   WHERE CTD_CLASSE='2'"+CRLF
cQry+= " 		 AND CTD_BLOQ='2'"+CRLF
cQry+= " 		 AND CTD.D_E_L_E_T_=''"+CRLF
cQry+= " ) AS TMP"+CRLF
cQry+= " WHERE CTA_REGRA<>'NULL'"+CRLF
cQry+= " GROUP BY CTA_FILIAL"+CRLF
cQry+= " 	  ,CTA_REGRA"+CRLF
cQry+= " 	  ,CTA_DESC"+CRLF
cQry+= " 	  ,CTA_NIVEL"+CRLF
cQry+= " 	  ,CTA_CONTA"+CRLF
cQry+= " 	  ,CTA_CUSTO"+CRLF
cQry+= " 	  ,CTA_ITEM"+CRLF
cQry+= " 	  ,CTA_CLVL"+CRLF
cQry+= " 	  ,CTA_ENTI05"+CRLF
cQry+= " ORDER BY CTA_REGRA,CTA_ITREGR"+CRLF+CRLF

IF TCSQLEXEC(cQry) < 0
	cMsg:= "Erro ao montar a tebela temporaria de amarrações!"
	lRet:= .F.				
ENDIF

IF lRet		
	cQry:= "DELETE "+RETSQLNAME("CTA")
	IF TCSQLEXEC(cQry) < 0
		cMsg:= "Problema ao excluir as amarrações!"
		lRet:= .F.		
	ENDIF
	
	IF lRet	
		cQry:= " INSERT INTO "+RETSQLNAME("CTA")+CRLF
		cQry+= " 	   (CTA_FILIAL,CTA_REGRA,CTA_DESC,CTA_NIVEL,CTA_ITREGR,CTA_CONTA,CTA_CUSTO,CTA_ITEM,CTA_CLVL,CTA_ENTI05,R_E_C_N_O_)"+CRLF		
		cQry+= " SELECT CTA_FILIAL"+CRLF
		cQry+= " 	  ,CTA_REGRA"+CRLF
		cQry+= " 	  ,CTA_DESC"+CRLF
		cQry+= " 	  ,CTA_NIVEL"+CRLF
		cQry+= " 	  ,REPLICATE('0',4-LEN(CONVERT(VARCHAR(4),CTA_ITREGR))) + CONVERT(VARCHAR(4),CTA_ITREGR) AS CTA_ITREGR"+CRLF
		cQry+= " 	  ,CTA_CONTA"+CRLF
		cQry+= " 	  ,CTA_CUSTO"+CRLF
		cQry+= " 	  ,CTA_ITEM"+CRLF
		cQry+= " 	  ,CTA_CLVL"+CRLF
		cQry+= " 	  ,CTA_ENTI05"+CRLF
		cQry+= " 	  ,R_E_C_N_O_"+CRLF
		cQry+= " FROM TMPCTA"+CRLF
		cQry+= " ORDER BY R_E_C_N_O_"+CRLF		
			
		IF TCSQLEXEC(cQry) < 0
			cMsg:= "Erro ao realizar a carga da tebela de amarrações!"
			lRet:= .F.	
		ELSE
			cMsg:= "Processo de carga das amarrações realizada com sucesso!!"
		ENDIF
	ENDIF
ENDIF

IF lJob 
	C34S01NOT(cMsg)
ELSEIF "SUCESSO"$UPPER(cMsg)
	MSGINFO(cMsg)
ELSE
	MSGALERT(cMsg)	
ENDIF

RETURN lRet
/*/{Protheus.doc} C34S01NOT
Notifica por e-mail a conclusão da amarração
@author carlos.henrique
@since 31/01/2018
@version undefined
@param cMsg, characters, descricao
@type function
/*/
Static Function C34S01NOT(cMsg)
Local cMensagem	:= ""
Local lOk			:= .F.
Local lSendOk		:= .T.
Local cError		:= ""
Local cPassword 	:= AllTrim(GetNewPar("MV_RELPSW"," "))
Local lAutentica	:= GetMv("MV_RELAUTH",,.F.)         			//Determina se o Servidor de Email necessita de Autenticação
Local cAccount  	:= AllTrim(GetNewPar("MV_RELACNT"," ")) 		//Conta a ser utilizada no envio de E-Mail
Local cUserAut  	:= Alltrim(GetNewPar("MV_RELAUSR",cAccount))	//Usuario para Autenticação no Servidor de Email
Local cPassAut  	:= Alltrim(GetNewPar("MV_RELAPSW",cPassword))	//Senha para Autenticação no Servidor de Email
Local cServer   	:= AllTrim(GetNewPar("MV_RELSERV",""))
Local nTimeOut  	:= GetNewPar("MV_RELTIME",120)
Local cMailConta	:= cAccount
Local cSubject  	:= ""
Local cEmail 		:= AllTrim(GetNewPar("MV_WFADMIN"," "))
	
U_uCONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CCTBS01] Realizando Notificação "+CEMPANT+"-"+CFILANT+"=> AMARRAÇÃO CTA")

//Gera HTML com todos os itens da planilha foram finalizado
cMensagem := '<html>'+CRLF
cMensagem += '<head>'+CRLF
cMensagem += '  <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">'+CRLF
cMensagem += '  <title>Notificação ESB</title>'+CRLF
cMensagem += '</head>'+CRLF
cMensagem += '  <body>'+CRLF
cMensagem += '	<table style="width: 100%;" border="1" cellspacing="1">'+CRLF
cMensagem += '	  <tbody>'+CRLF
cMensagem += '		<tr><td colspan="2" align="Left" width="100%" bgcolor="#3F5B7B"><b><i><font face="Arial" size="3" color="#FFFFFF">Notificação Retorno ESB:</font></i></b></td></tr>'+CRLF
cMensagem += '		<tr><td style="width: 10%;FONT-WEIGHT: bold;">DATA:</td><td style="width: 90%;">'+DTOC(DDATABASE)+'</td></tr>'+CRLF
cMensagem += '		<tr><td style="width: 10%;FONT-WEIGHT: bold;">HORA:</td><td style="width: 90%;">'+TIME()+'</td></tr>'+CRLF
cMensagem += '		<tr><td style="width: 10%;FONT-WEIGHT: bold;">Mensagem:</td><td style="width: 90%;">'+cMsg+'</td></tr>'+CRLF
cMensagem += '	  </tbody>'+CRLF
cMensagem += '	</table>'+CRLF
cMensagem += '  </body>'+CRLF
cMensagem += '</html>'+CRLF

//Envia Email 
If !Empty(cServer) .And. !Empty(cAccount) .And. (!Empty(cPassword) .OR. !Empty(cPassAut))
	
	// Conecta uma vez com o servidor de e-mails
	CONNECT SMTP SERVER cServer ACCOUNT cAccount PASSWORD cPassword TIMEOUT nTimeOut Result lOk
	
	If !lOK
		//Erro na conexao com o SMTP Server
		GET MAIL ERROR cError
		MsgStop("Não foi possível efetuar a conexão com o servidor de e-mail !" + cError,"Atenção")
	Else		//Envio de e-mail HTML
		cSubject	:= "Notificação do processo de amarração CTA - "+CEMPANT+"-"+CFILANT
		
		If lAutentica
			If !MailAuth(cAccount,cPassword)
				GET MAIL ERROR cError
				MsgStop("Erro de autenticação no servidor SMTP:" + cError,"Atenção")
			Endif
		Endif
		
		SEND MAIL FROM cMailConta to cEMail SUBJECT cSubject BODY cMensagem RESULT lSendOk
		
		If !lSendOk
			//Erro no Envio do e-mail
			GET MAIL ERROR cError
			MsgStop("Erro ao enviar e-mail para Responsáavel da Planilha!" + cError,"Atenção")
		EndIf
	EndIf
EndIf

// Desconecta com o servidor de e-mails
If lOk
	DISCONNECT SMTP SERVER
EndIf


Return