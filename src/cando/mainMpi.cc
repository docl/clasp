#define	DEBUG_LEVEL_FULL

#include <string>
#include "core/foundation.h"
#include "core/bundle.h"
#include "core/object.h"
#include "core/lisp.h"
#include "core/archiveNode.h"
#include "core/package.h"
#include "core/cons.h"
#include "core/candoOpenMp.h"
#include "core/packageLoader.h"
#include "chem/chemPackage.h"
#include "units/unitsPackage.h"
#include "openmmPackage/openmmPackage.h"
#include "kinematics/kinematicsPackage.h"
#include "candoMpi.h"



//
// Include main.cc 
// but this time USE_MPI will be defined and
// MPI code will be enabled
//





int main(int argc, char* argv[] )
{	// Do not touch debug log until after MPI init

    int maxThreads = 1;
//#pragma omp parallel shared(maxThreads)
    {
//#pragma omp single 
	{
	    maxThreads = core::cando_omp_get_num_threads();
	}
    }
    printf("CANDO starting (maxThreads:%d)\n", maxThreads );
    int rank = 0;
    int msize = 1;
    bool mpiEnabled = false;
#ifdef USE_MPI
    try
    {
	Mpi_O::Init(argc,argv,mpiEnabled,rank,msize);
    } catch (HardError& err)
    {
	printf("Could not start MPI\n");
	exit(1);
    }
#endif
    printf("CANDO mpi rank/size = (%d/%d)\n", rank, msize );
    core::LispHolder lispHolder(mpiEnabled,rank,msize);
    printf("About to get _lisp rank(%d)\n", rank);
    core::Lisp_sp _lisp = lispHolder.lisp();

    //
    // Install the packages that we will use
    //


    LOG(BF("Started LispHolder with mpiEnabled(%d) mpiRank(%d) mpiSize(%d)") % mpiEnabled % rank % msize );
    printf("%s:%d#%d About to startup lisp\n", __FILE__, __LINE__, rank);
    lispHolder.startup(argc, argv, "CANDO_APP");
    installAllCommonPackages(_lisp);
    printf("%s:%d#%d About to start try\n", __FILE__, __LINE__, rank);
    try
    {_BLOCK_TRACE("main loop");
	
	printf("%s:%d#%d About to run\n", __FILE__, __LINE__, rank);
	_lisp->run();
	return 0;
    } catch (core::Condition& cond)
    {
		//
		// Unhandled conditions end up here
		//
	Object_sp cb = cond.conditionObject();
	_lisp->print(BF("Caught Condition!"));
	_lisp->print(BF("%s") % cb->__str__());
	_lisp->print(BF(""));
	return 1;
    } catch ( core::ExitProgram& err)
    {
	printf("Caught ExitProgram at %s:%d\n", __FILE__, __LINE__);
    } catch ( ... )
    {
	_lisp->print(BF("Unknown exception in main %s:%d") %  __FILE__ % __LINE__);
    }

    _lisp->print(BF("CANDO terminated normally - exiting main"));
    return 0;
}

