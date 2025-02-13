resource ResMay = ParamMay ** open Prelude, Predef in {

--------------------------------------------------------------------------------
-- Nouns
oper

  Noun : Type = {
    s : NForm => Str
    } ;
  Noun2 : Type = Noun ** {c2 : Preposition} ;
  Noun3 : Type = Noun2 ** {c3 : Preposition} ;

  CNoun : Type = Noun ** {
    heavyMod : Str ; -- heavy stuff like relative clauses after determiner
    } ;

  PNoun : Type = Noun ;

  mkNoun : Str -> Noun = \anjing -> {
    s = table {
      NF Sg p => anjing + ParamMay.poss2str p ;
      NF Pl p => duplicate anjing + ParamMay.poss2str p
      }
    } ;

  useN : Noun -> CNoun = \n -> n ** {
    heavyMod = []
    } ;

---------------------------------------------
-- Pronoun

  Pronoun : Type = {
    s : Str ;
    p : Person ; -- for relative clauses
    empty : Str ; -- need to avoid GF being silly. See https://inariksit.github.io/gf/2018/08/28/gf-gotchas.html#metavariables-or-those-question-marks-that-appear-when-parsing
    } ;

  mkPron : Str -> Person -> Pronoun = \str,p -> {
    s = str ;
    p = p ;
    empty = []
    } ;
---------------------------------------------
-- NP

  NounPhrase : Type = {
    s : Possession => Str ; -- maybe need to keep +nya etc. open for becoming possessed? TODO check
    a : NPAgr ; -- NP can be made out of nouns and pronouns, need to retain its origin
    empty : Str ; -- need to avoid GF being silly. See https://inariksit.github.io/gf/2018/08/28/gf-gotchas.html#metavariables-or-those-question-marks-that-appear-when-parsing
    } ;

  emptyNP : NounPhrase = {
    s = \\_ => [] ;
    a = NotPron ;
    empty = []
    } ;

--------------------------------------------------------------------------------
-- Det, Quant, Card, Ord

  Quant : Type = {
    s : Str ;
    sp : NForm => Str ;
    poss : Possession ;
    } ;

  Determiner : Type = Quant ** {
    pr : Str ; -- prefix for numbers
    n : NumType ; -- number as in 5 (noun in singular), Sg or Pl
    } ;

  CardNum : Type = {
    s : Str ;
    } ;

  Num : Type = CardNum ** {
    n : NumType
    } ;

  baseNum : Num = {
    s = [] ;
    n = NoNum Sg
    } ;

  CardOrdNum : Type = CardNum ** {
    ord : Str
    } ;

  DigNum : Type = {
    s : CardOrd => Str ;
    } ;

  baseQuant : Quant = {
    s = [] ;
    sp = \\_ => [] ;
    poss = Bare ;
    } ;

  mkQuant : Str -> Quant = \str -> baseQuant ** {
    s = str ;
    sp = \\_ => str
    } ;

--------------------------------------------------------------------------------
-- Prepositions

  Preposition : Type = {
    s : Str ;             -- dengan
    obj : Person => Str ; -- dengan+nya -- needed in relative clauses to refer to the object
    prepType : PrepType ; -- TODO rename, the name is confusing
    } ;

  mkPrep : Str -> Preposition = \dengan -> {
    s = dengan ;
    obj = \\p => dengan + poss2str (Poss p) ;
    prepType = OtherPrep ;
    } ;

  -- direct object: "hits him" -> "memukul+nya"
  dirPrep : Preposition = {
    s = [] ;
    obj = table {
      P1 => BIND ++ "ku" ;
      P2 => BIND ++ "mu" ;
      P3 => BIND ++ "nya" } ;
    prepType = DirObj ;
    } ;

  -- truly empty
  emptyPrep : Preposition = {
    s = [] ;
    obj = \\_ => [] ;
    prepType = EmptyPrep ;
    } ;

  datPrep : Preposition = mkPrep "kepada" ;

  applyPrep : Preposition -> NounPhrase -> Str = \prep,np ->
    case <np.a, prep.prepType> of {
      <IsPron p,OtherPrep> => prep.obj ! p ++ np.empty ;
      _                    => prep.s ++ np.s ! Bare
    } ;

--------------------------------------------------------------------------------
-- Adjectives

  Adjective : Type = SS ;
  Adjective2 : Type = Adjective ;

  mkAdj : Str -> Adjective = \str -> {s = str} ;

  AdjPhrase : Type = Adjective ; -- ** {compar : Str} ;
--------------------------------------------------------------------------------
-- Verbs

  Verb : Type = {
    s : VForm => Str
    } ;
  Verb2 : Type = Verb ** {
    c2 : Preposition ;
    passive : Str
    } ;

  Verb3 : Type = Verb2 ** {
    c3 : Preposition
    } ;

--  VV : Type = Verb ** {vvtype : VVForm} ;

  mkVerb : Str -> Prefix -> Verb = \str,p -> {
    s = table {
      Root => str ;
      Active => prefix p str
      }
    } ;

  mkVerb2 : Verb -> Preposition -> Verb2 = \v,pr -> v ** {
    c2 = pr ;
    passive = "di" + v.s ! Root -- TODO check
    } ;

  mkVerb3 : Verb -> (p,q : Preposition) -> Verb3 = \v,p,q ->
    mkVerb2 v p ** {c3 = q} ;

  copula : Verb = {s = \\_ => "ada"} ; -- TODO
------------------
-- Adv

  Adverb : Type = SS ;

------------------
-- VP

  VerbPhrase : Type = {
    s : VForm => Polarity => Str ; -- tidak or bukan
    } ;

  VPSlash : Type = VerbPhrase ** {
    c2 : Preposition ;
    } ;

  useV : Verb -> VerbPhrase = \v -> v ** {
    s = \\vf,pol => verbneg pol ++ v.s ! vf
    } ;

  useComp : Str -> VerbPhrase = \s -> {
    s = \\vf,pol => nounneg pol ++ s ;
    } ;

  verbneg : Polarity -> Str = \pol -> case pol of {
    Neg => "tidak" ; -- or "tak"?
    Pos => []
    } ;

  nounneg : Polarity -> Str = \pol -> case pol of {
    Neg => "bukan" ;
    Pos => []
    } ;
--------------------------------------------------------------------------------
-- Cl, S

  Clause : Type = {
    subj : Str ;
    pred : VForm => Polarity => Str -- Cl may become relative clause, need to keep open VForm
    } ;

  RClause : Type = {
    subj : Str ;
    pred : Person => Polarity => Str
    } ;

  RS : Type = {s : Person => Str} ;

  ClSlash : Type = Clause ** {c2 : Preposition} ;

  Sentence : Type = {s : Str} ;

  predVP : NounPhrase -> VerbPhrase -> Clause = \np,vp -> {
    subj = np.s ! Bare ;
    pred = vp.s
    } ;

  predVPSlash : NounPhrase -> VPSlash -> ClSlash = \np,vps ->
    predVP np <vps : VerbPhrase> ** {c2 = vps.c2} ;

--------------------------------------------------------------------------------
-- linrefs

}
