#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} CX31UPDT
Rotina de atualização de tabela no banco
@author carlos.henrique
@since 17/01/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
user function CX31UPDT()
Local aParam:= {}
Local aRet 	:= {}
Local aTabs := {}
Local nCnt  := 0

Aadd(aParam,{1,'Tabela',space(100),"","","","",100,.T.})

If Parambox(aParam,'Informe a tabela => Use virgula para mais de uma tabela',@aRet)
	aTabs:= StrTokArr(aRet[1],",")
	
	For nCnt:= 1 to len(aTabs)
		X31UPDTABLE(aTabs[nCnt])
	
		If __GetX31Error()
			MSGALERT(__GetX31Trace())
		ELSE
			CHKFILE(aTabs[nCnt])
		EndIf
	
	Next
		
EndIf
	
return