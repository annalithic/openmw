#include "pathgrid.hpp"
#include "cell.hpp"
#include "idcollection.hpp"

#include <sstream>

void CSMWorld::Pathgrid::load(ESM::ESMReader& esm, bool& isDeleted, const IdCollection<Cell>& cells)
{
    load(esm, isDeleted);

    // correct ID
    if (!mId.empty() && mId.getRefIdString()[0] != '#' && cells.searchId(mId) == -1)
    {
        std::ostringstream stream;
        stream << "#" << mData.mX << " " << mData.mY;
        mId = ESM::RefId::stringRefId(stream.str());
    }
}

void CSMWorld::Pathgrid::load(ESM::ESMReader& esm, bool& isDeleted)
{
    ESM::Pathgrid::load(esm, isDeleted);

    mId = mCell;
    if (mCell.empty())
    {
        std::ostringstream stream;
        stream << "#" << mData.mX << " " << mData.mY;
        mId = ESM::RefId::stringRefId(stream.str());
    }
}
