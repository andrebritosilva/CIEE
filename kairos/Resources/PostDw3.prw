#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

/*/{Protheus.doc} CONTRATO
Simula integra��o com a DW3
@author Danilo Jos� Grodzicki
@since 17/09/2019
@version undefined
@type class
/*/
WSRESTFUL DW3 DESCRIPTION "Simula integra��o com a DW3" FORMAT APPLICATION_JSON
	WSMETHOD POST; 
	DESCRIPTION "Teste para retorno da DW3";
	WSSYNTAX "/DW3"
END WSRESTFUL

/*/{Protheus.doc} POST
Simula integra��o com a DW3
@author Danilo Jos� Grodzicki
@since 17/09/2019
@/version undefined

@type function
/*/
WSMETHOD POST WSSERVICE DW3

Local cJson := ""

::SetContentType('application/json')

//cJson := '{ '
//cJson += '    "errorCode": 404, '
//cJson += '    "errorMessage": "Erro na integra��o com a DW3." '
//cJson += '} '

cJson := '{ '
cJson += '    "Message": "Integra��o com a DW3 realizada com sucesso." '
cJson += '} '

::SetResponse( cJson )

Return .T.