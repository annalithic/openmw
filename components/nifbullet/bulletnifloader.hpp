#ifndef OPENMW_COMPONENTS_NIFBULLET_BULLETNIFLOADER_HPP
#define OPENMW_COMPONENTS_NIFBULLET_BULLETNIFLOADER_HPP

#include <cassert>
#include <map>
#include <set>
#include <string>

#include <osg/BoundingBox>
#include <osg/Referenced>
#include <osg/ref_ptr>

#include <BulletCollision/CollisionShapes/btCompoundShape.h>

#include <components/debug/debuglog.hpp>
#include <components/nif/niffile.hpp>
#include <components/resource/bulletshape.hpp>

class btTriangleMesh;
class btCompoundShape;
class btCollisionShape;

namespace Nif
{
    struct NiAVObject;
    struct NiNode;
    struct NiGeometry;
    struct Parent;
}

namespace NifBullet
{

    /**
     *Load bulletShape from NIF files.
     */
    class BulletNifLoader
    {
    public:
        void warn(const std::string& msg) { Log(Debug::Warning) << "NIFLoader: Warn: " << msg; }

        [[noreturn]] void fail(const std::string& msg)
        {
            Log(Debug::Error) << "NIFLoader: Fail: " << msg;
            abort();
        }

        osg::ref_ptr<Resource::BulletShape> load(Nif::FileView file);

    private:
        bool findBoundingBox(const Nif::NiAVObject& node, const std::string& filename);

        struct HandleNodeArgs
        {
            bool mHasMarkers{ false };
            bool mAnimated{ false };
            bool mIsCollisionNode{ false };
            bool mAutogenerated{ false };
            bool mAvoid{ false };
        };

        void handleNode(const std::string& fileName, const Nif::NiAVObject& node, const Nif::Parent* parent,
            HandleNodeArgs args, Resource::VisualCollisionType& visualCollisionType);

        const Nif::NiNode* findRootCollisionNode(const Nif::NiAVObject& rootNode) const;

        void handleNiTriShape(const Nif::NiGeometry& nifNode, const Nif::Parent* parent, HandleNodeArgs args);

        std::unique_ptr<btCompoundShape, Resource::DeleteCollisionShape> mCompoundShape;
        std::unique_ptr<btCompoundShape, Resource::DeleteCollisionShape> mAvoidCompoundShape;

        osg::ref_ptr<Resource::BulletShape> mShape;
    };

}

#endif
