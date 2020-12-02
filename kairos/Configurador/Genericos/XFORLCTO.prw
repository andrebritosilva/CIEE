#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} XFORLCTO
Usado nos layouts dos arquivos remessa CNAB - HEADER LOTE - posiçoes 12 e 13 (Forma lancamento)
@author marcelo.moraes
@since 21/05/2020
@version undefined

@type class
/*/
User Function XFORLCTO()  

local cRet := "01" //Credito em conta

IF IsInCallStack("U_CJOBK03")  
	IF lGeraOP
		cRet := "10" //Ordem de pagamento
	Endif
endif

IF IsInCallStack("U_CFINA94")  
	IF _cTpCNAB="OP"
		cRet := "10" //Ordem de pagamento
	Endif
endif

return(cRet)