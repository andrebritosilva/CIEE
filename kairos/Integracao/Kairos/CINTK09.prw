#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

/*/{Protheus.doc} BANCOS
Serviço de consulta de bancos
@author Danilo José Grodzicki
@since 06/11/2019
@version undefined
@type class
/*/
WSRESTFUL BANCOS DESCRIPTION "Serviço consulta de bancos" FORMAT APPLICATION_JSON
	
	WSMETHOD GET; 
	DESCRIPTION "Realiza a consulta de bancos";
	WSSYNTAX "/BANCOS"
	
END WSRESTFUL
 
/*/{Protheus.doc} GET
Realiza a consulta dos bancos
@author Danilo José Grodzicki
@since 06/11/2019
@/version undefined

@type function
/*/
WSMETHOD GET WSSERVICE BANCOS

Local cJson   := ""
Local cTabBco := GetNextAlias()

Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""

::SetContentType('application/json')

// Selecionar somente os bancos marcados para exibição para o Kairós, campo A6_XKAIROS == "1"
BeginSql Alias cTabBco
	%noParser%
	SELECT SA6.A6_COD,
	       SA6.A6_NOME,
	       SA6.A6_AGENCIA,
	       SA6.A6_NOMEAGE,
	       SA6.A6_NUMCON
	FROM %TABLE:SA6% SA6
	WHERE SA6.A6_FILIAL = %xFilial:SA6%
	  AND SA6.A6_XKAIROS = '1'
	  AND SA6.%notDel%
EndSql

(cTabBco)->(DbSelectArea((cTabBco)))
(cTabBco)->(DbGoTop())
if (cTabBco)->(!Eof())
	cJson := '{'
	cJson += '	"bancos": ['
	while (cTabBco)->(!Eof())
		cJson += '	{'
		cJson += '		"banco": "' + EncodeUTF8(AllTrim((cTabBco)->A6_COD), "cp1252") + '",'
		cJson += '		"descricaoBanco": "' + EncodeUTF8(AllTrim((cTabBco)->A6_NOME), "cp1252") + '",'
		cJson += '		"agencia": "' + EncodeUTF8(AllTrim((cTabBco)->A6_AGENCIA), "cp1252") + '",'
		cJson += '		"descricaoAgencia": "' + EncodeUTF8(AllTrim((cTabBco)->A6_NOMEAGE), "cp1252") + '",'
		cJson += '		"conta": "' + EncodeUTF8(AllTrim((cTabBco)->A6_NUMCON), "cp1252") + '"'
		cJson += '	}'
		(cTabBco)->(DbSkip())
		if (cTabBco)->(!Eof())
			cJson += '	,'
		endif
	enddo
	cJson += '	]'
	cJson += '}'
else
	(cTabBco)->(DbCloseArea())
	U_GrvLogKa("CINTK09", "GET", "2", "Não foram encontrados dados.", cJson, oJson)
	Return U_RESTERRO(Self,"Não foram encontrados dados.")
endif

::SetResponse(cJson)

(cTabBco)->(DbCloseArea())

Return .T.