#ifndef _core_loadTimeValues_H_
#define _core_loadTimeValues_H_

#include "core/foundation.h"
#include "core/object.h"
#include "core/vectorObjectsWithFillPtr.h"
#include "core/loadTimeValues.fwd.h"



namespace core
{
    class LoadTimeValues_O : public T_O
    {
	LISP_BASE1(T_O);
	LISP_CLASS(core,CorePkg,LoadTimeValues_O,"LoadTimeValues");
    public: // Simple default ctor/dtor
	LoadTimeValues_O() : Base(), _Objects(_Nil<VectorObjectsWithFillPtr_O>()) {};
	virtual ~LoadTimeValues_O() {};

    public: // ctor/dtor for classes with shared virtual base
//    explicit LoadTimeValues_O(core::Class_sp const& mc) : T_O(mc), VectorObjectsWithFillPtr(mc) {};
//    virtual ~LoadTimeValues_O() {};

    private: // instance variables here
	VectorObjectsWithFillPtr_sp 	_Objects;
        gctools::Vec0<Symbol_sp>	_Symbols; // TODO: Make this VectorSymbolsWithFillPtr_sp
	
    public: // Functions here
	static LoadTimeValues_sp make(int dataDimension, int symbolDimension);

	int numberOfValues() const { return this->_Objects->length(); };
	int numberOfSymbols() const { return this->_Symbols.size(); };

	void dump();

	// -------- Regular data storage

	void data_setFillPointer(uint i);
	T_sp& data_element(uint i);
	int data_vectorPushExtend(T_sp val, int extension);


	// -------- Symbols storage

	void symbols_setFillPointer(uint i);
	Symbol_sp& symbols_element(uint i);
	int symbols_vectorPushExtend(Symbol_sp val, int extension);

    }; // LoadTimeValues class





    /*! This class will be allocated in a non-moving pool and store a smart_ptr
      to a LoadTimeValuesPointer_sp to which pointers can be taken and guaranteed
      that they will not become stale */
    class MemoryLockedLoadTimeValuesPointer_O : public T_O
    {
        struct metadata_gc_do_not_move {};   // put this in a non-moveable pool
    private:
	LISP_BASE1(T_O);
	LISP_CLASS(core,CorePkg,MemoryLockedLoadTimeValuesPointer_O,"MemoryLockedLoadTimeValuePointer");
    public: // Simple default ctor/dtor
	MemoryLockedLoadTimeValuesPointer_O() : Base(), _LoadTimeValues(_Nil<LoadTimeValues_O>()) {};
	virtual ~MemoryLockedLoadTimeValuesPointer_O() {};
    private: // instance variables here
        LoadTimeValues_sp               _LoadTimeValues;
    public: // Functions here
	static MemoryLockedLoadTimeValuesPointer_sp make(LoadTimeValues_sp ltv) {
            GC_RESERVE(MemoryLockedLoadTimeValuesPointer_O,obj);
            obj->_LoadTimeValues = ltv;
            return obj;
        }

        LoadTimeValues_sp& ref() { return this->_LoadTimeValues; };
        LoadTimeValues_sp* ptr() { return &this->_LoadTimeValues; };

    }; //  class
    
}; // core namespace
TRANSLATE(core::LoadTimeValues_O);
TRANSLATE(core::MemoryLockedLoadTimeValuesPointer_O);

extern "C"
{
    /*! This stores a pointer to the smart_ptr to the run-time value vector.
      This is linked to by LLVM Modules generated by COMPILE.
      Original note 2013: We use a pointer to the smart_ptr because we don't want
      to have to maintain this as a garbage collection root.
      NOTE April 23, 2014 - Why don't we want this to be a garbage collection root???
      I'm going to treat it as a garbage collection root anyway - it seems like
      it will be full of objects that need to be rooted so that compiled code
      will maintain access to them.
    */
    extern core::LoadTimeValues_sp* 	globalRunTimeValuesVector ATTR_WEAK;
};





#endif /* _core_loadTimeValues_H_ */
