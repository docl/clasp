#ifndef	Bundle_H //[
#define Bundle_H



#include <stdio.h>
#include <string>
#include <vector>
#include <set>
#include "foundation.h"
#include "object.h"
#include "pathname.fwd.h"
#include "sourceFileInfo.fwd.h"
#include "boost/filesystem.hpp"

namespace core {


/*! Maintains the file paths to the different directories of the Cando bundle
 */
class	Bundle
{
#if defined(USE_MPS)
    friend mps_res_t globals_scan(mps_ss_t ss, void *p, size_t s);
#endif

private:
    bool		_Initialized;
    boost_filesystem::path _RootDir;
    boost_filesystem::path _AppDir;
    boost_filesystem::path _ResourcesDir;
    boost_filesystem::path _DatabasesDir;
    boost_filesystem::path _ScriptsDir;
    boost_filesystem::path _LispDir;
    boost_filesystem::path _LibDir;
    boost_filesystem::path _StartupWorkingDir;
public:

    /*! Initialize the bundle and set up all the paths
     */
private:
    boost_filesystem::path findAppDir(const string& argv0, const string& cwd, const string& env);
    void findSubDirectories(boost_filesystem::path p);
public:
    void initializeStartupWorkingDirectory();
    void initialize(const string& argv0, const string& appPathEnvironmentVariable);

    boost_filesystem::path getRootDir();
    boost_filesystem::path getAppDir();
    boost_filesystem::path getResourcesDir();
    boost_filesystem::path getDatabasesDir();
    boost_filesystem::path getScriptsDir();
    boost_filesystem::path getLispDir();
    boost_filesystem::path getLibDir();
    boost_filesystem::path getStartupWorkingDir();


    Pathname_sp getRootPathname();
    Pathname_sp getSysPathname();
    Pathname_sp getAppPathname();


    string describe();
    Bundle();


    virtual ~Bundle() {};
};


	/*! Get the system bundle */
//extern	Bundle&	bundle();


};
#endif //]
