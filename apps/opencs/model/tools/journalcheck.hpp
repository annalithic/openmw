#ifndef CSM_TOOLS_JOURNALCHECK_H
#define CSM_TOOLS_JOURNALCHECK_H

#include "../world/idcollection.hpp"

#include "../doc/stage.hpp"

namespace CSMDoc
{
    class Messages;
}

namespace CSMWorld
{
    class InfoCollection;
}

namespace ESM
{
    struct Dialogue;
}

namespace CSMTools
{
    /// \brief VerifyStage: make sure that journal infos are good
    class JournalCheckStage : public CSMDoc::Stage
    {
    public:
        JournalCheckStage(
            const CSMWorld::IdCollection<ESM::Dialogue>& journals, const CSMWorld::InfoCollection& journalInfos);

        int setup() override;
        ///< \return number of steps

        void perform(int stage, CSMDoc::Messages& messages) override;
        ///< Messages resulting from this stage will be appended to \a messages

    private:
        const CSMWorld::IdCollection<ESM::Dialogue>& mJournals;
        const CSMWorld::InfoCollection& mJournalInfos;
        bool mIgnoreBaseRecords;
    };
}

#endif
