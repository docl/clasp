       
       
//
// (C) 2004 Christian E. Schafmeister
//


#ifndef SymbolSet_H
#define SymbolSet_H
#include <stdio.h>
#include <string>
#include <vector>
#include <set>
#include "foundation.h"
#include "object.h"
#include "lispVector.h"
#include "hashTableEq.h"
#include "cons.h"


namespace core
{


class SymbolSetCartesianProductWrapper
{
public:
    virtual T_sp operator()(Symbol_sp obj1, Symbol_sp obj2) const = 0;
};


    SMART(Residue);
    SMART(SymbolSet);
    SMART(ObjectSet);
    SMART(SymbolList);
/*!
  A class that stores a set of strings
*/
    SMART(SymbolSet);
    class SymbolSet_O : public T_O
    {
	LISP_BASE1(T_O);
	LISP_CLASS(core,CorePkg,SymbolSet_O,"SymbolSet");
    public:
	void initialize();
#if defined(XML_ARCHIVE)
	void	archiveBase(ArchiveP node);
#endif // defined(XML_ARCHIVE)

    private:
	HashTableEq_sp          _Symbols;
    public:
	static SymbolSet_sp make(Cons_sp vals);
    public:

	SymbolSet_sp	copy();

	uint	size() const { return this->_Symbols->hashTableSize();};
	void	remove(Symbol_sp  s);
	bool	contains(Symbol_sp s);
	bool	containsSubset(SymbolSet_sp sub);
	void	insert(Symbol_sp s) { this->_Symbols->setf_gethash(s,s);};
	void	insertSymbolSet(SymbolSet_sp ss);
	void	insertSymbolList(SymbolList_sp ss);
	SymbolSet_sp insertConsSymbols(Cons_sp list);
	void	insertVectorStrings(const VectorStrings& symbolsAsStrings);
	void	insertVector(Vector_sp objs);
	void	clear();

	Cons_sp	asCons();

	bool	equal(T_sp ss) const;

	// Set theory operations

	//! A setUnion B = (x:x E A || x E B)
	SymbolSet_sp	setUnion(SymbolSet_sp b);

	//! A intersection B = (x:x E A && x E B)
	SymbolSet_sp	intersection(SymbolSet_sp b);

	//! A-B = (x: x E A && not x E B )
	SymbolSet_sp	relativeComplement(SymbolSet_sp b);

	SymbolSet_sp	removeAll(SymbolSet_sp b) { return this->relativeComplement(b); };

	//! AxB = ("x,y": x E A ; y E B )
	ObjectSet_sp	cartesianProduct(SymbolSet_sp b);


	/*! AxB = ("x,y": x E A ; y E B )
	 * Return AxB as defined by a wrapper
	 */
	ObjectSet_sp cartesianProductWrapped(SymbolSet_sp b, const SymbolSetCartesianProductWrapper& wrapper);

	string	asString();
        std::ostream&	dumpToStream( std::ostream& o );

	string __repr__() const;

	SymbolSet_O( const SymbolSet_O& ss ); //!< Copy constructor

        void map(std::function<void(Symbol_sp)> const& fn);
        void map(std::function<void(Symbol_sp)> const& fn) const;

	DEFAULT_CTOR_DTOR(SymbolSet_O);
    };


};


TRANSLATE(core::SymbolSet_O);
#endif


