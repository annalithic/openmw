#include "loaddoor.hpp"

#include "esmreader.hpp"
#include "esmwriter.hpp"

namespace ESM
{
    void Door::load(ESMReader& esm, bool& isDeleted)
    {
        isDeleted = false;
        mRecordFlags = esm.getRecordFlags();

        bool hasName = false;
        while (esm.hasMoreSubs())
        {
            esm.getSubName();
            switch (esm.retSubName().toInt())
            {
                case SREC_NAME:
                    mId = esm.getRefId();
                    hasName = true;
                    break;
                case fourCC("MODL"):
                    mModel = esm.getHString();
                    break;
                case fourCC("FNAM"):
                    mName = esm.getHString();
                    break;
                case fourCC("SCRI"):
                    mScript = esm.getRefId();
                    break;
                case fourCC("SNAM"):
                    mOpenSound = esm.getRefId();
                    break;
                case fourCC("ANAM"):
                    mCloseSound = esm.getRefId();
                    break;
                case SREC_DELE:
                    esm.skipHSub();
                    isDeleted = true;
                    break;
                default:
                    esm.fail("Unknown subrecord");
                    break;
            }
        }

        if (!hasName)
            esm.fail("Missing NAME subrecord");
    }

    void Door::save(ESMWriter& esm, bool isDeleted) const
    {
        esm.writeHNCString("NAME", mId.getRefIdString());

        if (isDeleted)
        {
            esm.writeHNString("DELE", "", 3);
            return;
        }

        esm.writeHNCString("MODL", mModel);
        esm.writeHNOCString("FNAM", mName);
        esm.writeHNOCString("SCRI", mScript.getRefIdString());
        esm.writeHNOCString("SNAM", mOpenSound.getRefIdString());
        esm.writeHNOCString("ANAM", mCloseSound.getRefIdString());
    }

    void Door::blank()
    {
        mRecordFlags = 0;
        mName.clear();
        mModel.clear();
        mScript = ESM::RefId::sEmpty;
        mOpenSound = ESM::RefId::sEmpty;
        mCloseSound = ESM::RefId::sEmpty;
    }
}
